# linefollowapk

Aplikacja do sterowania robotem typu linefollow

## Wymagania
1. Aplikacja łączy się za pomocą Wi-Fi.
2. Korzystamy z protokołu UDP do przesyłania danych.
3. Kod komunikacji jest w `comunication.cpp`, jest to większość komunikacji ze strony robota.
4. Dodatkowo mamy komunikaty z robota typu:
   `if (now - lastMillis >= interval) {
    lastMillis = now;
    String pos = "Position: " + String(position);
    com_send(pos.c_str());
    com_send("!");
    request_sensorsRaw();
   }`
   Jest to wyciągnięty kod z robota.
5. Aplikacja ma być tylko na telefon Android.
6. Aplikacja ma zapisywać ustawienia.
7. Gdy nagłe rozłączenie z robotem, ma pójść próba ponownej komunikacji (3 requesty). Gdy nie uda się uzyskać odpowiedzi, ma wyskoczyć powiadomienie o zerwanej komunikacji.
8. Gdy tylko robot od nowa się połączy, ma zostać sprawdzone, czy nie uległ on ponownemu uruchomieniu lub utracił zapisane wartości. Jak uległ restartowi, ma być odpowiedni komunikat.
9. Ma mieć minimum 9 przycisków do sterowania robotem typu: `Start_comunication`, `Stop_comunication`, `Start_calibration`, `Start_Robot`, `Stop_robot`, `Reset_Robot`, `Send_pparams`, `Request_params`, `Reset_app`.
10. Ma mieć 7 pól wprowadzania minimum: `Kp`, `Ki`, `Kd`, `Max`, `Base`, `Turn`, `Lost_th`.
11. Aplikacja ma mieć miejsce w pamięci na 5 zapisów wartości z pól wprowadzania, po to by szybko przełączać się między ustawieniami robota. Fajnie gdyby każdy config miał przycisk, by na niego się przełączyć.
12. Wizualizacja odczytanych wartości z czujników. Jest to robot, który ma albo 8 albo 16 czujników koloru i chcę, by te czujniki były wyświetlane. W zależności, czy wykrywają linię, czy nie, odpowiednio się zapalały. Powyżej nich chcę mieć podgląd na raw wartości otrzymane od robota.
13. Przesyłanie większej ilości wartości do debugowania na przyszłość, jak powyższe podpunkty działają bez problemów. Na razie nie chcę zmieniać kodu robota. Myślę nad przesyłaniem `td`, `error`, wyników PID (wejście, wyjście), ustawień mocy silników.

## Current Development Status

### Completed Tasks

*   **Project Setup:**
    *   Initialized Flutter project and updated `main.dart` to use a custom `HomePage`.
    *   Added `udp` package for UDP communication.
    *   Added `shared_preferences` package for data persistence.
*   **PID Configuration Management:**
    *   Created `PidParameters` data model (`lib/pid_parameters.dart`).
    *   Implemented `PidConfigManager` for saving, loading, and managing up to 5 PID configurations (`lib/pid_config_manager.dart`).
    *   Integrated PID configuration selectors and save/load functionality into `HomePage`.
*   **UDP Communication Integration:**
    *   Created `UdpService` to handle UDP send/receive, including connection status and heartbeat logic (`lib/udp_service.dart`).
    *   Integrated `UdpService` into `HomePage`, including:
        *   UI for entering robot IP, robot port, and app listen port.
        *   "Start Comms" and "Stop Comms" buttons.
        *   Display of connection status and last received message.
        *   Automatic retry mechanism (3 attempts) on disconnection with notifications.
        *   Placeholder for `_robotLastKnownState` and logic to detect robot restarts/state changes based on "ROBOT_STATUS:" messages.
*   **Sensor Visualization:**
    *   Added state variables `_rawSensorValues` and `_lineDetectionStatus` to `HomePage` to store sensor data.
    *   Implemented parsing logic in `_messageSubscription` for "SENSORS:" (raw values) and "LINE:" (line detection) messages.
    *   Created `_buildSensorVisualization()` to visually display raw sensor values and line detection status (circles changing color).
*   **Debugging Values Display:**
    *   Added `_debuggingValues` state variable to `HomePage`.
    *   Implemented parsing logic in `_messageSubscription` for "DEBUG:" messages to update `_debuggingValues`.
    *   Integrated a section to display `_debuggingValues` in the UI.

### Remaining Tasks

*   **Complete Control Button Functionality:**
    *   Implement the full functionality for all 9 control buttons, including "Start Calib", "Start Robot", "Stop Robot", "Reset Robot", and "Reset App". Currently, only "Start Comms", "Stop Comms", "Send Params", and "Request Params" have basic integration with UDP.
*   **Robot Restart/Value Loss Check Refinement:**
    *   Refine the logic for checking robot restarts and lost values. This requires specific messages from the robot that indicate its status and whether its stored values have been reset. The current implementation is a placeholder.
*   **PID Parameter Handling:**
    *   Implement logic to update the PID parameter input fields when parameters are requested from the robot and received via UDP.
*   **Android Compatibility Testing:**
    *   Thoroughly test the application on an Android device to ensure full compatibility and proper functionality.
*   **Error Handling and UI Feedback:**
    *   Enhance error handling and provide more detailed UI feedback for various scenarios (e.g., failed send, invalid IP/port).

## Robot Communication Standard for Debugging

To enable robust debugging and data visualization in the mobile application, the robot's firmware needs to adhere to a specific UDP communication protocol for sending debugging information. All messages should be sent as plain text strings.

### General Message Format

All debugging messages should start with a specific prefix followed by a colon and then the data.

*   **ROBOT_STATUS:** To indicate robot state or restart.
    *   **Format:** `ROBOT_STATUS:<status_string>`
    *   **Example:** `ROBOT_STATUS:Ready`, `ROBOT_STATUS:Restarted`
    *   **Purpose:** The app will use this to detect if the robot has restarted or changed its operational state, prompting a notification.

*   **SENSORS:** To send raw sensor values.
    *   **Format:** `SENSORS:<value1>,<value2>,...,<valueN>`
    *   **Example (8 sensors):** `SENSORS:1023,800,500,200,150,300,700,900`
    *   **Example (16 sensors):** `SENSORS:1023,800,500,200,150,300,700,900,100,200,300,400,500,600,700,800`
    *   **Purpose:** Visualize the raw analog/digital readings from the color sensors.

*   **LINE:** To send line detection status for each sensor.
    *   **Format:** `LINE:<status1>,<status2>,...,<statusN>` (where 1 is line detected, 0 is no line)
    *   **Example (8 sensors):** `LINE:0,0,0,1,1,0,0,0`
    *   **Example (16 sensors):** `LINE:0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0`
    *   **Purpose:** Visually represent which sensors are currently detecting the line.

*   **DEBUG:** For general debugging information including PID components, motor settings, and cycle time.
    *   **Format:** `DEBUG:TD:<td_value>,Error:<error_value>,PID_In:<pid_input>,PID_Out:<pid_output>,Motor_L:<motor_left_power>,Motor_R:<motor_right_power>,CycleTime:<cycle_time_ms>`
    *   **Example:** `DEBUG:TD:5.2,Error:0.1,PID_In:12.3,PID_Out:50.0,Motor_L:180,Motor_R:200,CycleTime:10`
    *   **Purpose:** Display detailed debugging information from the robot's control loop. The app will parse these key-value pairs to display relevant data.

### Requesting and Sending PID Parameters (from app to robot)

*   **Request Parameters:**
    *   **Message:** `REQ_PID`
    *   **Purpose:** App sends this to the robot to request its current PID parameters.
*   **Send Parameters:**
    *   **Message:** `SET_PID:<json_string_of_pid_parameters>`
    *   **Purpose:** App sends this to the robot to set new PID parameters. The JSON string should correspond to the `PidParameters` class structure.
    *   **Example (JSON for PidParameters):**
        ```json
        {"kp":1.2,"ki":0.1,"kd":0.5,"max":255.0,"base":100.0,"turn":50.0,"lostTh":500.0}
        ```

This detailed communication standard will ensure a clear interface between the robot firmware and the Flutter application, facilitating robust debugging and control.