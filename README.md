# Kifu Cam
Use your iPhone to take a picture of a Go board and export the sgf.

Export to SmartGo or CrazyStone for editing or counting, or send the sgf as email.

# How to Build
Download the project tarball [here](https://s3-us-west-2.amazonaws.com/ahn-uploads/kifu-cam.tar.gz).

Then, assuming you're on a Mac and have Xcode:

```
tar xzvf kifu-cam.tar.gz
cd kifu-cam
git pull origin master
open KifuCam.xcodeproj
```

Connect your iPhone, hit the play button.

# Details
Kifu Cam is written without *.xib files or storyboards.
If you are looking for a pure code iOS project, you found one.

All user interface stuff is written in Objective-C.

The algorithmic core makes heavy use of OpenCV and is written in C++.
Feel free to pilfer and reuse.

# Purchase
Kifu Cam is in the App Store.
