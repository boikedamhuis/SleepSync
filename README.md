# **Polar Flow Sleep Sync App**
Are you also a happy owner of a Polar watch? Do you also want to registrate all your sleep in Apple Health and view it in that way? Polar sucks at making this happen, that's why We decided to develop it ourselfs. Feel free to use it.

# Why?
Since iOS 8.0 are you able to monitor a lot of "health" related data using the Health app on your iPhone. Polar does write your steps and workouts, but not your sleep. This app fills the gap and makes it happen to sync your sleep to Apple Health. 

# How to install?
Make sure you have at least installed Xcode 6 and set up a developer account. 
First, clone this repo:
```
	$ git clone https://github.com/boikedamhuis/SleepSync
```
Secondly, you have to install all the pods to make sure everything works well.
```
	$ cd SleepSync
	$ pod install
	$ open .
```
Open `PolarSync.xcworkspace` using Xcode on your Mac.
Fill in your creditionals on top of PolarSync > Managers > RRDownloader.m and run the app on your iPhone. 
From now on it will sync all your sleep to Apple Health using this little app. Keep the app open in the background to make sure it keeps working. 

Happy ~~training~~ sleeping!

Feel free to send me push requests

---
