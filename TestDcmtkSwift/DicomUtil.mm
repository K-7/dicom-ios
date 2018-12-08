//
//  DicomUtil.cpp
//  DCMTKSample
//
//  Created by Sean Ashton on 24/07/2015.
//  Copyright (c) 2015 Schimera Pty Ltd. All rights reserved.
//

#include "DicomUtil.h"
#include <zlib.h>         /* for zlibVersion() */

#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmdata/dctk.h"          /* for various dcmdata headers */
#include "dcmtk/dcmdata/cmdlnarg.h"      /* for prepareCmdLineArgs */
#include "dcmtk/dcmdata/dcuid.h"         /* for dcmtk version name */
#include "dcmtk/dcmdata/dcrledrg.h"      /* for DcmRLEDecoderRegistration */

#include "dcmtk/dcmimgle/dcmimage.h"      /* for DicomImage */
#include "dcmtk/dcmimgle/digsdfn.h"       /* for DiGSDFunction */
#include "dcmtk/dcmimgle/diciefn.h"       /* for DiCIELABFunction */

#include "dcmtk/ofstd/ofconapp.h"      /* for OFConsoleApplication */
#include "dcmtk/ofstd/ofcmdln.h"       /* for OFCommandLine */

#include "dcmtk/dcmimage/diregist.h"      /* include to support color images */
#include "dcmtk/ofstd/ofstd.h"         /* for OFStandard */
#include "dcmtk/dcmimage/dipitiff.h"     /* for dcmimage TIFF plugin */
#include "dcmtk/dcmimage/dipipng.h"      /* for dcmimage PNG plugin */

#include "dcmtk/ofstd/ofstream.h"
#include "dcmtk/dcmjpeg/djdecode.h"
#include "dcmtk/dcmjpeg/dipijpeg.h"
#include "dcmtk/dcmimage/dipipng.h"

#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmnet/scp.h"
#include "dcmtk/dcmnet/dstorscp.h"
#include "dcmtk/dcmnet/assoc.h"
#include "dcmtk/dcmnet/dimse.h"
#include "dcmtk/dcmnet/dfindscu.h"

@implementation DicomUtil

const char* OurAETitle = "CURASC";
const int OurPort = 8089;
const char* DestinationAETitle = "CURASC";
const char* PeerAETitle = "NHBLRPACS";
const char* PeerIPAddress = "10.1.36.102";
const char* PeerIPAddressAndPort = "10.1.36.102:2350";
const int PeerPort = 2350;
const char* TestMRN = "10010000678862";

+(void) test {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"I_000001" ofType:@"dcm"];
    DcmDataDictionary& dict = dcmDataDict.wrlock();
    dict.loadDictionary([[[NSBundle mainBundle] pathForResource:@"private" ofType:@"dic"] cStringUsingEncoding:NSASCIIStringEncoding]);
    dcmDataDict.unlock();
    if (!dcmDataDict.isDictionaryLoaded()) {
        NSLog(@"Data dictionary not loaded");
    } else {
        NSLog(@"Data dictionary loaded!");
    }
    DcmRLEDecoderRegistration::registerCodecs(OFFalse /*pCreateSOPInstanceUID*/, OFFalse);
    DJDecoderRegistration::registerCodecs(EDC_photometricInterpretation, EUC_default, EPC_default, OFFalse);
    DcmFileFormat *dfile = new DcmFileFormat();
    
    OFCondition cond = dfile->loadFile([filePath cStringUsingEncoding:NSASCIIStringEncoding], EXS_Unknown, EGL_withoutGL, DCM_MaxReadLength, ERM_autoDetect);
    if (cond.bad()) {
        NSLog(@"Something wrong loading DCM file");
    } else {
        NSLog(@"File Loaded");
    }
    Sint32 frameCount;
    
    if (dfile->getDataset()->findAndGetSint32(DCM_NumberOfFrames, frameCount).bad()) {
        frameCount = 1;
    }
    NSLog(@"Frame count %d", frameCount);
    DcmStack stack;
    DcmObject *dobject = NULL;
    DcmElement *delem = NULL;
    const char *tagName = NULL;
    const char *tagValue = NULL;
    const char *tagValue2 = NULL;
    OFCondition status = dfile->getDataset()->nextObject(stack, OFTrue);
    while (status.good()) {
        dobject = stack.top();
        
        delem = (DcmElement *)dobject;
        DcmTag tag = delem->getTag();
        tagName = tag.getTagName();
        
        OFCondition valOk = dfile->getDataset()->findAndGetString(tag, tagValue);
        if (valOk.good() && tagValue) {
            if ((tag == DCM_SOPClassUID) || (tag == DCM_SOPInstanceUID)) {
                if (tagValue) {
                    tagValue2 = dcmFindNameOfUID(tagValue);
                }
            }
            if (tagValue2) {
                NSLog(@"%@ %@",[NSString stringWithCString:tagName encoding:NSUTF8StringEncoding], [NSString stringWithCString:tagValue2 encoding:NSUTF8StringEncoding] );
                tagValue2 = NULL;
            } else if (tagValue) {
                 NSLog(@"%@ %@",[NSString stringWithCString:tagName encoding:NSUTF8StringEncoding], [NSString stringWithCString:tagValue encoding:NSUTF8StringEncoding] );               
                tagValue = NULL;
            }
        }
        status = dfile->getDataset()->nextObject(stack, OFTrue);
    }
}

+(NSString *)extractFirstFrame {
    DcmDataDictionary& dict = dcmDataDict.wrlock();
    dict.loadDictionary([[[NSBundle mainBundle] pathForResource:@"private" ofType:@"dic"] cStringUsingEncoding:NSASCIIStringEncoding]);
    dcmDataDict.unlock();
    if (!dcmDataDict.isDictionaryLoaded()) {
        NSLog(@"Data dictionary not loaded");
    } else {
        NSLog(@"Data dictionary loaded!");
    }
    DcmRLEDecoderRegistration::registerCodecs(OFFalse /*pCreateSOPInstanceUID*/, OFFalse);
    DJDecoderRegistration::registerCodecs(EDC_never, EUC_default, EPC_default, OFFalse);
    DJDecoderRegistration::registerCodecs(); // register JPEG codecs
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"I_000002" ofType:@"dcm"];
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *parentFolder = [cacheFolder stringByAppendingPathComponent:@"dicom"];
    [[NSFileManager defaultManager] createDirectoryAtPath:parentFolder withIntermediateDirectories:YES attributes:nil error:nil];
    DcmFileFormat *dfile = new DcmFileFormat();
    
    OFCondition cond = dfile->loadFile([filePath cStringUsingEncoding:NSASCIIStringEncoding], EXS_Unknown, EGL_withoutGL, DCM_MaxReadLength, ERM_autoDetect);
    if (cond.bad()) {
        NSLog(@"Something wrong loading DCM file");
    }
    
    Sint32 frameCount;
    
    if (dfile->getDataset()->findAndGetSint32(DCM_NumberOfFrames, frameCount).bad()) {
        frameCount = 1;
    }
    E_TransferSyntax xfer = dfile->getDataset()->getOriginalXfer();
    DicomImage *di = new DicomImage(dfile, xfer, CIF_UsePartialAccessToPixelData, 0 /*frame*/,frameCount /*frame count*/);
    if (di == NULL) {
        NSLog(@"Out of memory");
        return nil;
    }
    
    if (di->getStatus() != EIS_Normal)
    {
        const char *msg = DicomImage::getString(di->getStatus());
        NSLog(@"Some other error");
        //        OFLOG_FATAL(dcm2pnmLogger, DicomImage::getString(di->getStatus()));
        return nil;
    }
    /****/
    DcmStack stack;
    DcmObject *dobject = NULL;
    OFCondition status = dfile->getDataset()->nextObject(stack, OFTrue);
    
    
    dobject = stack.top();
    
    /****/
    //const char *XferText = DcmXfer(xfer).getXferName();
    const char *SOPClassUID = NULL;
    const char *SOPInstanceUID = NULL;
    const char *SOPClassText = NULL;
    const char *colorModel;
    dfile->getDataset()->findAndGetString(DCM_SOPClassUID, SOPClassUID);
    dfile->getDataset()->findAndGetString(DCM_SOPInstanceUID, SOPInstanceUID);
    
    
    colorModel = di->getString(di->getPhotometricInterpretation());
    if (colorModel == NULL)
        colorModel = "unknown";
    if (SOPInstanceUID == NULL)
        SOPInstanceUID = "not present";
    if (SOPClassUID == NULL)
        SOPClassText = "not present";
    else
        SOPClassText = dcmFindNameOfUID(SOPClassUID);
    if (SOPClassText == NULL)
        SOPClassText = SOPClassUID;
    if (di->isMonochrome()) {
        NSLog(@"Is monochrome");
    }
    unsigned long count;
    
    di->hideAllOverlays();
    count = di->getWindowCount();
    di->setMinMaxWindow(1);
    NSLog(@"VOI windows in file %ld", count);
    int frame = 1;
    int result = 0;
    DcmDataset *dictionary;
    dictionary = dfile->getDataset();
    
    
    
    NSString *filename = [NSString stringWithFormat:@"frame%d.jpg",frame];
    NSString *outputFile = [parentFolder stringByAppendingPathComponent:filename];
    FILE *ofile = fopen([outputFile cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    DiJPEGPlugin plugin;
    plugin.setQuality(OFstatic_cast(unsigned int, 90));
    plugin.setSampling(ESS_422);
    result = di->writePluginFormat(&plugin, ofile, frame);
    fclose(ofile);
    
    
    delete di;
    DcmRLEDecoderRegistration::cleanup();
    DJDecoderRegistration::cleanup();
    return outputFile;
}


+(void) cecho {
    T_ASC_Network *net; // network struct, contains DICOM upper layer FSM etc.
    ASC_initializeNetwork(NET_REQUESTOR, 0, 1000 /* timeout */, &net);
    T_ASC_Parameters *params; // parameters of association request
    ASC_createAssociationParameters(&params, ASC_DEFAULTMAXPDU);
    
    // set calling and called AE titles
    ASC_setAPTitles(params, "ECHOSCU", PeerAETitle, NULL);
    
    // the DICOM server accepts connections at server.nowhere.com port 104
    ASC_setPresentationAddresses(params, "localhost", PeerIPAddressAndPort);
    
    // list of transfer syntaxes, only a single entry here
    const char* ts[] = { UID_LittleEndianImplicitTransferSyntax };
    // add presentation context to association request
    ASC_addPresentationContext(params, 1, UID_VerificationSOPClass, ts, 1);
    // request DICOM association
    T_ASC_Association *assoc;
    if (ASC_requestAssociation(net, params, &assoc).good())
    {
        if (ASC_countAcceptedPresentationContexts(params) == 1)
        {
            // the remote SCP has accepted the Verification Service Class
            DIC_US id = assoc->nextMsgID++; // generate next message ID
            DIC_US status; // DIMSE status of C-ECHO-RSP will be stored here
            DcmDataset *sd = NULL; // status detail will be stored here
            // send C-ECHO-RQ and handle response
           DIMSE_echoUser(assoc, id, DIMSE_BLOCKING, 0, &status, &sd);
            if(status == STATUS_Success){
                NSLog(@"c-echo success");
            }
            delete sd; // we don't care about status detail
        }
    }
    ASC_releaseAssociation(assoc); // release association
    ASC_destroyAssociation(&assoc); // delete assoc structure
    ASC_dropNetwork(&net); // delete net structure
}


+(void) cfind {
    DcmSCU * DicomSCU = new DcmSCU();
    
    DicomSCU->setAETitle(OurAETitle);
    DicomSCU->setPeerAETitle(PeerAETitle);
    DicomSCU->setPeerHostName(PeerIPAddress);
    DicomSCU->setPeerPort(PeerPort);
    
    DicomSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    DicomSCU->setDIMSETimeout(2);
    DicomSCU->setMaxReceivePDULength(ASC_DEFAULTMAXPDU);
    
    OFList<OFString> TransferSyntaxes;
    TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
    
    DicomSCU->addPresentationContext(UID_FINDStudyRootQueryRetrieveInformationModel, TransferSyntaxes);
    
    OFCondition result = DicomSCU->initNetwork();
    
    result = DicomSCU->negotiateAssociation();
    
    T_ASC_PresentationContextID cxID = DicomSCU->findPresentationContextID(UID_FINDStudyRootQueryRetrieveInformationModel, "");
    
    DcmDataset findParams;
    //Query level - Patient
    findParams.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
    
    //Query key - patient id
    findParams.putAndInsertString(DCM_PatientID, TestMRN);
    
    //Query parameters, filled by the responding SCP
    findParams.putAndInsertString(DCM_StudyDate, "");
    findParams.putAndInsertString(DCM_StudyTime, "");
    findParams.putAndInsertString(DCM_AccessionNumber, "");
    findParams.putAndInsertString(DCM_PatientName, "");
    findParams.putAndInsertString(DCM_StudyID, "");
    findParams.putAndInsertString(DCM_PatientSex, "");
    findParams.putAndInsertString(DCM_StudyInstanceUID, "");
    findParams.putAndInsertString(DCM_RequestingService, "");
    findParams.putAndInsertString(DCM_PlacerOrderNumberImagingServiceRequest , "");
    findParams.putAndInsertString(DCM_FillerOrderNumberImagingServiceRequest, "");
    
    OFList<QRResponse*> responses;
    result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
    
    
    DcmDataset *dset;
    OFListIterator(QRResponse*) it = responses.begin();
    while (it != responses.end())
    {
        QRResponse* rsp = *it;
        dset =  rsp->m_dataset;
        
        if (dset != NULL)
        {
            OFString PatientName;
            OFString StudyDate;
            OFString StudyTime;
            OFString PatientSex;
            OFString AccessionNumber;
            OFString StudyInstanceUID;
            OFString RequestingService;
            OFString FillerOrderNumber;
            OFString PlacerOrderNumber;
          
           if(dset->findAndGetOFString(DCM_PatientName, PatientName).good()){
                NSLog(@"This is the patient name %@", @(PatientName.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_StudyDate, StudyDate).good()){
                NSLog(@"This is the study date %@", @(StudyDate.c_str()));
            }

            if(dset->findAndGetOFString(DCM_StudyTime, StudyTime).good()){
                NSLog(@"This is the study time %@", @(StudyTime.c_str()));
            }

            if(dset->findAndGetOFString(DCM_PatientSex, PatientSex).good()){
                NSLog(@"This is the patient sex %@", @(PatientSex.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_AccessionNumber, AccessionNumber).good()){
                NSLog(@"This is the Accession Number %@", @(AccessionNumber.c_str()));
            }
           
            if(dset->findAndGetOFString(DCM_StudyInstanceUID, StudyInstanceUID).good()){
                NSLog(@"This is the Study Instance UID  %@", @(StudyInstanceUID.c_str()));
            }

            if(dset->findAndGetOFString(DCM_RequestingService, RequestingService).good()){
                NSLog(@"This is the Requesting Service  %@", @(RequestingService.c_str()));
            }
          
            if(dset->findAndGetOFString(DCM_FillerOrderNumberImagingServiceRequest, FillerOrderNumber).good()){
                NSLog(@"This is the Filler Order  %@", @(FillerOrderNumber.c_str()));
            }

            if(dset->findAndGetOFString(DCM_PlacerOrderNumberImagingServiceRequest, PlacerOrderNumber).good()){
                NSLog(@"This is the Placer Order  %@", @(PlacerOrderNumber.c_str()));
            }

            
            NSLog(@"c-find success");
        }
        
        it++;
    }
    
    DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
    delete DicomSCU;
    
}

+(void) cmove0{
    DcmSCU * MoveSCU = new DcmSCU();

    MoveSCU->setAETitle(OurAETitle);
    MoveSCU->setPeerAETitle(PeerAETitle);
    MoveSCU->setPeerHostName(PeerIPAddress);
    MoveSCU->setPeerPort(PeerPort);

    MoveSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    MoveSCU->setDIMSETimeout(2);
    MoveSCU->setMaxReceivePDULength(ASC_DEFAULTMAXPDU);

    OFList<OFString> TransferSyntaxes;
    TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
    TransferSyntaxes.push_back(UID_BigEndianExplicitTransferSyntax);
    TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);

    MoveSCU->addPresentationContext(UID_FINDPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
    MoveSCU->addPresentationContext(UID_MOVEPatientRootQueryRetrieveInformationModel, TransferSyntaxes);

    OFCondition result = MoveSCU->initNetwork();
    if (result.bad()) {
        DCMNET_ERROR("Unable to set up the network: " << result.text());
    }
    
    result = MoveSCU->negotiateAssociation();
    if (result.bad()) {
        DCMNET_ERROR("Unable to negotiate association: " << result.text());
    }
    
    DcmDataset moveParams;
    //Query level - Patient
    moveParams.putAndInsertString(DCM_QueryRetrieveLevel, "PATIENT");

    //Query key - patient id
    moveParams.putAndInsertString(DCM_PatientID, TestMRN);

    //Query parameters, filled by the responding SCP
    moveParams.putAndInsertString(DCM_StudyDate, "");
    moveParams.putAndInsertString(DCM_StudyTime, "");
    moveParams.putAndInsertString(DCM_AccessionNumber, "");
    moveParams.putAndInsertString(DCM_PatientName, "");
    moveParams.putAndInsertString(DCM_StudyID, "");
    moveParams.putAndInsertString(DCM_PatientSex, "");
    
    T_ASC_PresentationContextID presID = MoveSCU->findPresentationContextID(UID_MOVEPatientRootQueryRetrieveInformationModel, "");
    if (presID == 0) {
        DCMNET_ERROR("There is no uncompressed presentation context for Patient Root MOVE");
    }
    
    OFList<RetrieveResponse*> moveResponses;
    result = MoveSCU->sendMOVERequest(presID, DestinationAETitle, &moveParams, &moveResponses);

    Uint32 fileCount = 1;
    DcmDataset *dset;
    OFListIterator(RetrieveResponse*) it = moveResponses.begin();
    while (it != moveResponses.end() && result.good())
    {
        RetrieveResponse* rsp = *it;
        dset =  rsp->m_dataset;

        if (dset != NULL)
        {
            OFString PatientName;
            OFString StudyDate;
            OFString StudyTime;
            OFString StudyUID;
            OFString PatientSex;

            if(dset->findAndGetOFString(DCM_PatientName, PatientName).good()){
                NSLog(@"This is the patient name %@", @(PatientName.c_str()));
            }

            if(dset->findAndGetOFString(DCM_StudyDate, StudyDate).good()){
                NSLog(@"This is the study date %@", @(StudyDate.c_str()));
            }

            if(dset->findAndGetOFString(DCM_StudyTime, StudyTime).good()){
                NSLog(@"This is the study time %@", @(StudyTime.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_StudyID, StudyUID).good()){
                NSLog(@"This is the study instance id %@", @(StudyUID.c_str()));
            }

            if(dset->findAndGetOFString(DCM_PatientSex, PatientSex).good()){
                NSLog(@"This is the patient sex %@", @(PatientSex.c_str()));
            }
            NSLog(@"c-move success");
            DCMNET_INFO("Received study #" << std::setw(4) << fileCount << ": " << StudyUID.c_str());
            fileCount++;
        }

        it++;
    }

    MoveSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
    delete MoveSCU;
}


+(void) setupMoveScp {
    OFCondition status;
    DcmStorageSCP * scp = new DcmStorageSCP();
    scp->setPort(OurPort);
    scp->setAETitle(OurAETitle);
    scp->setMaxReceivePDULength(16384);
    scp->setACSETimeout(30);
    scp->setDIMSETimeout(30);
    scp->setConnectionTimeout(10);
    scp->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    scp->setVerbosePCMode(OFFalse);
    scp->setRespondWithCalledAETitle(OFFalse);
    scp->setHostLookupEnabled(OFTrue);
    scp->setDirectoryGenerationMode(DcmStorageSCP::DGM_NoSubdirectory);
    scp->setFilenameGenerationMode(DcmStorageSCP::FGM_SOPInstanceUID);
    scp->setFilenameExtension(".dcm");
    scp->setDatasetStorageMode(DcmStorageSCP::DGM_StoreToFile);
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"storescp" ofType:@"cfg"];
    
    status = scp->loadAssociationConfiguration([configPath cStringUsingEncoding:NSASCIIStringEncoding], "default");
    if (status.bad()) {
        DCMNET_ERROR("Cannot load association configuration: " << status.text());
    }
    NSLog(@"\nconfig file path: %@", configPath);
    

    NSString *outputDirPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject].absoluteString;
    outputDirPath = [NSString stringWithFormat:@"%@/DicomViewer/dcm",outputDirPath];
    outputDirPath = [outputDirPath substringFromIndex:7]; // To get rid of "file://"
    status = scp->setOutputDirectory([outputDirPath cStringUsingEncoding:NSASCIIStringEncoding]);
    if (status.bad()) {
        DCMNET_ERROR("Cannot specify output directory:" << outputDirPath <<" ---- "<< status.text());
    }
    NSLog(@"\noutput directory path: %@", outputDirPath);
    
    NSLog(@"Attempting to listen on port 8089...");
    status = scp->listen();
    if (status.bad()) {
        DCMNET_ERROR("Cannot start SCP and listen on port 8089" << status.text());
        return;
    }
    
}

+(void) cmove{
    DcmSCU * MoveSCU = new DcmSCU();
        
    MoveSCU->setAETitle(OurAETitle);
    MoveSCU->setPeerAETitle(PeerAETitle);
    MoveSCU->setPeerHostName(PeerIPAddress);
    MoveSCU->setPeerPort(PeerPort);
    
    MoveSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    MoveSCU->setDIMSETimeout(2);
    MoveSCU->setMaxReceivePDULength(ASC_DEFAULTMAXPDU);
    
    OFList<OFString> TransferSyntaxes;
    TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
    TransferSyntaxes.push_back(UID_BigEndianExplicitTransferSyntax);
    TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
    
    MoveSCU->addPresentationContext(UID_FINDPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
    MoveSCU->addPresentationContext(UID_MOVEPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
    
    OFCondition result = MoveSCU->initNetwork();
    if (result.bad()) {
        DCMNET_ERROR("Unable to set up the network: " << result.text());
    }
    
    result = MoveSCU->negotiateAssociation();
    if (result.bad()) {
        DCMNET_ERROR("Unable to negotiate association: " << result.text());
    }
    
    T_ASC_PresentationContextID presID = MoveSCU->findPresentationContextID(UID_FINDPatientRootQueryRetrieveInformationModel, "");
    
    DcmDataset moveParams;
    //Query level - Patient
    moveParams.putAndInsertString(DCM_QueryRetrieveLevel, "PATIENT");
    
    //Query key - patient id
    moveParams.putAndInsertString(DCM_PatientID, TestMRN);
    
    //Query parameters, filled by the responding SCP
    moveParams.putAndInsertString(DCM_StudyDate, "");
    moveParams.putAndInsertString(DCM_StudyTime, "");
    moveParams.putAndInsertString(DCM_AccessionNumber, "");
    moveParams.putAndInsertString(DCM_PatientName, "");
    moveParams.putAndInsertString(DCM_StudyInstanceUID, "");
    moveParams.putAndInsertString(DCM_Modality, "");
    moveParams.putAndInsertString(DCM_PatientSex, "");
    
    OFList<QRResponse*> findResponses;
    result = MoveSCU->sendFINDRequest(presID, &moveParams, &findResponses);
    
    presID = MoveSCU->findPresentationContextID(UID_MOVEPatientRootQueryRetrieveInformationModel, "");
    if (presID == 0) {
        DCMNET_ERROR("There is no uncompressed presentation context for Patient Root MOVE");
    }
    
    
    Uint32 fileCount = 1;
    DcmDataset *dset;
    OFListIterator(QRResponse*) it = findResponses.begin();
    
    while (it != findResponses.end() && result.good())
    {
        QRResponse* rsp = *it;
        dset =  rsp->m_dataset;
        
        if (dset != NULL)
        {
            OFString PatientName;
            OFString StudyDate;
            OFString StudyTime;
            OFString AccessionNumber;
            OFString StudyInstanceUID;
            OFString Modality;
            OFString PatientSex;
            
            if(dset->findAndGetOFString(DCM_PatientName, PatientName).good()){
                NSLog(@"This is the patient name %@", @(PatientName.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_StudyDate, StudyDate).good()){
                NSLog(@"This is the study date %@", @(StudyDate.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_AccessionNumber, AccessionNumber).good()){
                NSLog(@"This is the accession number %@", @(AccessionNumber.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_StudyTime, StudyTime).good()){
                NSLog(@"This is the study time %@", @(StudyTime.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_StudyInstanceUID, StudyInstanceUID).good()){
                NSLog(@"This is the study instance id %@", @(StudyInstanceUID.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_Modality, Modality).good()){
                NSLog(@"This is the Modality %@", @(Modality.c_str()));
            }
            
            if(dset->findAndGetOFString(DCM_PatientSex, PatientSex).good()){
                NSLog(@"This is the patient sex %@", @(PatientSex.c_str()));
            }
            
            result = MoveSCU->sendMOVERequest(presID, DestinationAETitle, &moveParams, NULL);
            if (result.good()) {
                DCMNET_INFO("Received study #" << std::setw(4) << fileCount << ": " << StudyInstanceUID.c_str());
                fileCount++;
            }
        }
        
        it++;
    }
    
    MoveSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
    delete MoveSCU;
}

@end
