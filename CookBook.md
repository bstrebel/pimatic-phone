# Pimatic phone-plugin cookbook

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/screenshots/iframe.png" width="1020">

Step-by-step instructions to setup a phone device with Google iFrame
mapping, geocoding and iCloud update control as outlined in the above
screenshot.

## Essentials
1. Install pimatic-phone **plugin**, go to plugin settings and enter at
   least the Home location (name=home, tag=Home) for the device. Enter
   latitude/longitude (radius=250) and address for your home location as
   well as the SSID of your home WiFi access point. Enter additional
   locations you want to use in location based rules. You might left the
   GPS coordinates empty and use geocoding (see below) to let Google
   fill in latitude and longitude for the location.
2. Add the **PhoneDevice** (id=phone_PHONE, name=Bob's iPhone, debug=Yes) and
   review all the other device settings
3. Go to **page** settings and add the phone device
4. Use device **API** (updateTag) or **rule actions** (set tag of ...) to play
   around with your new phone device

## iFrame device
1. Register Google project and activate **Google Maps Embed API** and **Google
   Maps Geocoding API** and write down the generated API key.
2. Install [patched pimatic-iframe plugin](https://github.com/bstrebel/pimatic-iframe), restart pimatic
3. Create a display **group** for phone components with id=group_PHONE
4. Create **iframeDevice** (id=iframe_PHONE, name=Current location of
   Bob's iPhone, width=99%, url=https://www.google.com/maps/embed/v1/place?key={key}&q={address})
5. Create **DummySwitch** device (id=iframe_switch_PHONE, name=Enable iFrame
   updates for Bob's iPhone)
6. Update iFrame section of the phone_PHONE device configuration
   (id=iframe_PHONE, switch=iframe_switch_PHONE) and enter the API key
   from 1. in the googleMaps section
7. Update page and group settings
8. Turn on iFrame updates and check console output and/or pimatic-daemon.log

## Geocoding
1. Create **Variable** $address_PHONE (type=Value)
2. Create **VariableInputDevice** (id=input_address_PHONE,
   variable=address_PHONE)
3. Create a **ButtonsDevice** (id=buttons_address_PHONE,
   text=Geolocation tools for PHONE) with 2 buttons
   (id=button_set_address_PHONE, text=set device address and
   id=button_update_locations_PHONE, text=update plugin locations)
4. Create rules (id=set_address_PHONE, name=Set location of Bob's iPhone
   and id=update_locations_PHONE)
   ```
   when button_set_address_PHONE is pressed then set address of phone_PHONE to "$address_PHONE"
   ```
   ```
   when button_update_locations_PHONE is pressed then execute \
    "curl --user admin:admin --silent --request GET http://localhost:8080/api/device/phone_PHONE/updatePluginConfig"
   ```
Enter address tokens (including your own location tags) and check the
results of (reverse) geocoding on the map. Create location based rules
and check them by manuall change the device location, and, ...

## iCloud Settings (to be completed)

**a) without 2FA**

1. Create **DummySwitch** (id=icloud_switch_PHONE)
2. Update device configuration (iCloudSwitch=icloud_switch_PHONE)

**b) with 2FA**

1. Create **Variable** $verify_PHONE
2. Create **VariableInputDevice** (variable=verify_PHONE)
3. Create **ButtonsDevice** (id=buttons_icloud_Phone) with two buttons
   (button_suspend_PHONE and button_resume_PHONE)
4. Create suspend and resume **rules**
   ```
   when button_suspend_PHONE is pressed then suspend phone_PHONE
   ```
   ```
   when button_resume_PHONE is pressed then resume phone_PHONE with "$verify_PHONE"
   ```

## Mobile device configuration
1. Android: use Tasker, pimatic-location app, Locative or any other
   geofencing app to update the device location by calling the
   appropriate API function
2. iOS: configure iCloud updates for the device or install a suitable
   gefencing app like Locative
