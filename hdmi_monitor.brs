'hdmi_monitor v2.0.0
Function hdmi_Initialize(msgPort As Object, userVariables As Object, bsp As Object)
    print "HDMI Monitor"
    print ""
    hdmiMonitor = newHdmiMonitor(msgPort, userVariables, bsp)
    return hdmiMonitor
End Function

Function newHdmiMonitor(msgPort As Object, userVariables As Object, bsp As Object)
    s = {}

    s.version = 1.1
    s.msgPort = msgPort
    s.userVariables = userVariables
    s.bsp = bsp
    s.ProcessEvent = hdmi_ProcessEvent
    s.debug = true
    s.customLoggingCode = "1600"

    s.timer = CreateObject("roTimer")
    s.timer.SetPort(msgPort)
    s.timer.SetElapsed(10, 0) 
    s.timer.Start()

    s.last_hdmi_status = invalid
    s.last_power_status = invalid
    
    HdmiCheck(s)

    return s
End Function

Function HdmiCheck(s as Object)
    print "HDMI Check"

    vm = CreateObject("roVideoMode")
    if vm = invalid then
        goto end_hdmi
    else
        status = vm.GetHdmiOutputStatus()
        if status = invalid then
            if s.last_hdmi_status = true or s.last_hdmi_status = invalid then 
                printinfo(s,"HDMI deconnecte")
                s.last_hdmi_status = false
                goto end_hdmi
            end if
        else
        current_hdmi_status = status.output_present
        current_power_status = status.output_powered
            if s.last_hdmi_status <> current_hdmi_status or s.last_power_status <> current_power_status then
                s.last_hdmi_status = current_hdmi_status
                s.last_power_status = current_power_status
                if current_hdmi_status then
                    printinfo(s,"HDMI connecte")
                    if status.output_powered then
                        printinfo(s,"Ecran ON")
                        edid_screen = vm.GetEdidIdentity(true)
                        if edid_screen = invalid then
                            printinfo(s,"EDID non disponible")
                            goto end_hdmi
                        else
                            if edid_screen.DoesExist("manufacturer") then
                                manufacturer = "- Fabriquant : " + edid_screen["manufacturer"]
                            else
                                manufacturer = "- Fabriquant : N/A"
                            end if

                            if edid_screen.DoesExist("monitor_name") then
                                monitorName = "- Nom : " + edid_screen["monitor_name"]
                            else
                                monitorName = "- Nom : N/A"
                            end if

                            if edid_screen.DoesExist("serial_number_string") then
                                serial = "- Numero de serie : " + edid_screen["serial_number_string"]
                            else
                                serial = "- Numero de serie : N/A"
                            end if

                            if edid_screen.DoesExist("year_of_manufacture") then
                                year = "- Annee fabrication : " + str(edid_screen["year_of_manufacture"])
                            else
                                year = "- Annee fabrication : N/A"
                            end if
                            printinfo(s,"EDID Ecran :")
                            printinfo(s, manufacturer)
                            printinfo(s, monitorName)
                            printinfo(s, serial)
                            printinfo(s, year)
                        end if
                    else 
                        printinfo(s,"Ecran OFF")
                    end if
                end if
            end if
        end if
    end if

end_hdmi:
    print "End HDMI Check"
    print ""
End Function

Function printinfo(s as Object, info as String)
    print info
    s.bsp.logging.WriteDiagnosticLogEntry(s.customLoggingCode, info)
End Function

Function hdmi_ProcessEvent(event As Object) as Boolean
    if type(event) = "roTimerEvent" then
        HdmiCheck(m)
        m.timer.SetElapsed(10, 0)
        m.timer.Start()
    end if
    return false
End Function