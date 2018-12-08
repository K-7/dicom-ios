## About

I have integrated ImebraBuild library into my swift code to retrive DICOM files through TCP streaming and display the images using a webview.
The webview renders the DICOM files using a DicomViewer called dwv(https://github.com/ivmartel/dwv) written in Jquery-Mobile.

I am loading the webViewer folder into my resource bundle. 

The TCP streamed & downloaded DICOM images are also stored into resource bundle so that webViewer picks it up from the respective folders and renders them.

I had to setup ORTHANC light weight mini-PAC server (https://www.orthanc-server.com/) in my local machine and 
configure its AET, serverPort 


### Usefull links
``` 
## DICOM details
http://dicomiseasy.blogspot.com/


## DICOM server
https://www.orthanc-server.com/static.php?page=download-mac

## Remote DICOM server
http://dicomserver.co.uk/

## IOS Plugin
https://imebra.com/get-it/

```



``` ADD libimebra.a into "Link Binary With Libraries" under Build Phases ```

## Compile and integrate DCMTK library into swift project 

DICOM image processing using Imebra

[Imebra Offical Guide](https://imebra.com/wp-content/uploads/documentation/html/quick_tour.html)

## Prerequisite
  * [Download Imebra 4.2](https://imebra.com/get-it/)
  * [Download Cmake](https://cmake.org/download/)

## ImebraBuild Setup

As per the Imebra official guide compile and generate library using command line as follows,

##### For iOS

```
mkdir imebra_for_ios
cd imebra_for_ios
cmake your_imebra_location -DIOS=IPHONE
cmake --build .
```
##### For iOS-Simulator

```
mkdir imebra_for_ios_simulator
cd imebra_for_ios_simulator
cmake your_imebra_location -DIOS=SIMULATOR
cmake --build .
```

In both compilation, libimebra.a will be generated.

##### Combine Static Libraries

lipo -create libimebra.a libimebra.a -o libimebraUniversal.a

> Note: libimebra.a one is iPhone(armv7,armv7s architecture) and another one for simulator(i386,x86_64 architecture).
Rename libimebraUniversal.a to libimebra.a

## Xcode Setup

* Select Target -> Build Phase -> Link Binary with libraries -> Click "+" to add the libraries libimebra.a, libiconv.tbd and libc++.tbd

* Select Target -> Build Settings -> Search Paths -> Library Search Paths -> add Imebra build location (imebra_for_ios or imebra_for_ios_simulator) with recursive

That's it Clean and Build.