# Tasker Setup Guide
[project]: https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/Pimatic.prj.xml

You may use the [example project][project] as a starting point for your configuration.
Just download the project file directly to your phone ("Save link as ...")
or use other methods to transfer the file "Pimatic.prj.xml" to the download directory.

Experienced users import the project file in Tasker and change the url and device name
in the _HTTP Get_ action.

See [Location Without Tears](http://tasker.dinglisch.net/userguide/en/loctears.html) for some background information regarding device
location tracking without draining batteries in a few hours ...

If you start from scratch with Tasker on Android, the following guide will be helpful.

---
Download and install [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm&hl=de) from Google Play:

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/TaskerApp.png" width="640">

---
The project toolbar is visible in the advanced mode. First goto preferences
and disable Beginner mode:

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/Preferences.png" width="320">&nbsp;&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/BeginnerMode.png" width="320">

---
To import the project file into tasker, long press the Home icon on the
bottom left of Taskers main screen and navigate to the download directory
to select the sample project file.

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/ImportProject.png" width="320">&nbsp;&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/SelectFileDialog.png" width="320">

---
The project uses 2 generic profiles to trigger the phone update if you
establish a WiFi connection or your phone connects to another cellular
GSM/CDMA access point.

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/ProjectProfiles.png" width="320">&nbsp;&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/ProjectTasks.png" width="320">

---
The UpdatePhone task calls the pimatic API action and updates your phone
location in pimatic. Adjust the HTTP Get settings to your requirements.

<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/UpdatePhoneTask.png" width="320">&nbsp;&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/bstrebel/pimatic-phone/master/assets/UpdatePhoneEdit.png" width="320">



