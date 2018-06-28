//
//  WiFi.m
//  Network
//
//  Created by zhouqiang on 14/12/2017.
//

#import "WiFi.h"

@interface WiFi ()

@property (nonatomic,  copy) NSString  *SSID;
@property (nonatomic,  copy) NSString  *BSSID;
@property (nonatomic,  copy) NSData    *SSIDData;

@end

@implementation WiFi
- (instancetype)initWithSSID:(NSString *)SSID
                       BSSID:(NSString *)BSSID
                    SSIDData:(NSData   *)SSIDData
{
    self = [super init];
    if (self) {
        self.SSID = SSID;
        self.BSSID = BSSID;
        self.SSIDData = SSIDData;
    }
    return self;
}
#if TARGET_OS_OSX
+ (instancetype)instanceWithInterface:(CWInterface *)interface
{
    WiFi *retVal = [[WiFi alloc] init];
    return retVal;
}
#endif
@end
#if TARGET_OS_OSX
NSString *NSStringFromCWErr(CWErr err){
    switch (err) {
        case kCWNoErr:
            return @"No Error";
        case kCWEAPOLErr:
            return @"EAPOL Error";
        case kCWInvalidParameterErr:
            return @"Invalid Parameter";
        case kCWNoMemoryErr:
            return @"Memory Allocation Failed";
        case kCWUnknownErr:
            return @"Unknown Error";
        case kCWNotSupportedErr:
            return @"Operation Not Supported";
        case kCWInvalidFormatErr:
            return @"Invalid Protocol Element Field Detected";
        case kCWTimeoutErr:
            return @"Operation Timeout";
        case kCWUnspecifiedFailureErr:
            return @"Unspecified Failure";
        case kCWUnsupportedCapabilitiesErr:
            return @"Unsupported Capabilities";
        case kCWReassociationDeniedErr:
            return @"Reassociation Denied (Unable to determine that an association exists.)";
        case kCWAssociationDeniedErr:
            return @"Association Denied";
        case kCWAuthenticationAlgorithmUnsupportedErr:
            return @"Authentication Algorithm Unsupported";
        case kCWInvalidAuthenticationSequenceNumberErr:
            return @"Invalid Authentication Sequence Number";
        case kCWChallengeFailureErr:
            return @"Challenge Failure";
        case kCWAPFullErr:
            return @"AP Full";
        case kCWUnsupportedRateSetErr:
            return @"Unsupported Rate Set";
        case kCWShortSlotUnsupportedErr:
            return @"Short Slot Unsupported";
        case kCWDSSSOFDMUnsupportedErr:
            return @"DSSS-OFDM Unsupported";
        case kCWInvalidInformationElementErr:
            return @"Invalid Information Element";
        case kCWInvalidGroupCipherErr:
            return @"Invalid Group Cipher";
        case kCWInvalidPairwiseCipherErr:
            return @"Invalid Pairwise Cipher";
        case kCWInvalidAKMPErr:
            return @"Invalid Authentication Selector";
        case kCWUnsupportedRSNVersionErr:
            return @"Unsupported WPA/WPA2 Version";
        case kCWInvalidRSNCapabilitiesErr:
            return @"Invalid RSN Capabilities";
        case kCWCipherSuiteRejectedErr:
            return @"Cipher Suite Rejected For Network Security Policy";
        case kCWInvalidPMKErr:
            return @"PMK Rejected";
        case kCWSupplicantTimeoutErr:
            return @"WPA/WPA2 Handshake Timedout";
        case kCWHTFeaturesNotSupportedErr:
            return @"HT Features Not Supported";
        case kCWPCOTransitionTimeNotSupportedErr:
            return @"PCO Transition Time Not Supported";
        case kCWReferenceNotBoundErr:
            return @"Reference Not Bound (No interface is bound to the CWInterface object.)";
        case kCWIPCFailureErr:
            return @"IPC Failure (Error communicating with a separate process.)";
        case kCWOperationNotPermittedErr:
            return @"Operation Not Permitted";
        case kCWErr:
            return @"Generic Error";
    }
}
NSString *NSStringFromCWPHYMode(CWPHYMode mode){
    switch (mode) {
        case kCWPHYModeNone:
            return @"None";
        case kCWPHYMode11a:
            return @"IEEE 802.11a";
        case kCWPHYMode11b:
            return @"IEEE 802.11b";
        case kCWPHYMode11g:
            return @"IEEE 802.11g";
        case kCWPHYMode11n:
            return @"IEEE 802.11n";
        case kCWPHYMode11ac:
            return @"IEEE 802.11ac";
    }
}
NSString *NSStringFromCWInterfaceMode(CWInterfaceMode mode){
    switch (mode) {
        case kCWInterfaceModeNone:
            return @"None";
        case kCWInterfaceModeStation:
            return @"Non-AP Station";
        case kCWInterfaceModeIBSS:
            return @"IBSS";
        case kCWInterfaceModeHostAP:
            return @"HostAP";
    }
}
NSString *NSStringFromCWSecurity(CWSecurity mode){
    switch (mode) {
        case kCWSecurityNone:
            return @"Open WiFi";
        case kCWSecurityWEP:
            return @"WEP";
        case kCWSecurityWPAPersonal:
            return @"WPA Personal";
        case kCWSecurityWPAPersonalMixed:
            return @"WPA/WPA2 Personal";
        case kCWSecurityWPA2Personal:
            return @"WPA2 Personal";
        case kCWSecurityPersonal:
            return @"Personal";
        case kCWSecurityDynamicWEP:
            return @"Dynamic WEP";
        case kCWSecurityWPAEnterprise:
            return @"WPA Enterprise";
        case kCWSecurityWPAEnterpriseMixed:
            return @"WPA/WPA2 Enterprise";
        case kCWSecurityWPA2Enterprise:
            return @"WPA2 Enterprise";
        case kCWSecurityEnterprise:
            return @"Enterprise";
        case kCWSecurityUnknown:
            return @"Unknown";
    }
}
NSString *NSStringFromCWIBSSModeSecurity(CWIBSSModeSecurity mode){
    switch (mode) {
        case kCWIBSSModeSecurityNone:
            return @"System";
        case kCWIBSSModeSecurityWEP40:
            return @"WEP";
        case kCWIBSSModeSecurityWEP104:
            return @"WPA Personal";
    }
}
NSString *NSStringFromCWChannelWidth(CWChannelWidth mode){
    switch (mode) {
        case kCWChannelWidthUnknown:
            return @"Unknown";
        case kCWChannelWidth20MHz:
            return @"20MHz";
        case kCWChannelWidth40MHz:
            return @"40MHz";
        case kCWChannelWidth80MHz:
            return @"80MHz";
        case kCWChannelWidth160MHz:
            return @"160MHz";
    }
}
NSString *NSStringFromCWChannelBand(CWChannelBand mode){
    switch (mode) {
        case kCWChannelBandUnknown:
            return @"Unknown";
        case kCWChannelBand2GHz:
            return @"2.4GHz";
        case kCWChannelBand5GHz:
            return @"5GHz";
    }
}
NSString *NSStringFromCWCipherKeyFlags(CWCipherKeyFlags flag){
    if (flag == kCWCipherKeyFlagsNone) {
        return @"System";
    }
    NSMutableArray<NSString *> *flags = @[].mutableCopy;
    if (flag & kCWCipherKeyFlagsUnicast) {
        [flags addObject:@"Unicast Packets"];
    }
    if (flag & kCWCipherKeyFlagsMulticast) {
        [flags addObject:@"Multicast Packets"];
    }
    if (flag & kCWCipherKeyFlagsTx) {
        [flags addObject:@"Sent"];
    }
    if (flag & kCWCipherKeyFlagsRx) {
        [flags addObject:@"Received"];
    }
    NSString *retVal = [flags componentsJoinedByString:@" | "];
    return retVal;
}
NSString *NSStringFromCWKeychainDomain(CWKeychainDomain mode){
    switch (mode) {
        case kCWKeychainDomainNone:
            return @"None";
        case kCWKeychainDomainUser:
            return @"User Keychain,iCloud Keychain Preferred";
        case kCWKeychainDomainSystem:
            return @"System";
    }
}
NSString *NSStringFromCWEventType(CWEventType mode){
    switch (mode) {
        case CWEventTypeNone:
            return @"None";
        case CWEventTypePowerDidChange:
            return @"Power Changed";
        case CWEventTypeSSIDDidChange:
            return @"SSID Changed";
        case CWEventTypeBSSIDDidChange:
            return @"BSSID Changed";
        case CWEventTypeCountryCodeDidChange:
            return @"Country Code Changed";
        case CWEventTypeLinkDidChange:
            return @"Link State Changed";
        case CWEventTypeLinkQualityDidChange:
            return @"RSSI Or Transmit Rate Changed";
        case CWEventTypeModeDidChange:
            return @"Operating Mode Changed";
        case CWEventTypeScanCacheUpdated:
            return @"Scan Cache Updated";
        case CWEventTypeVirtualInterfaceStateChanged:
            return @"Virtual Interface State Changed";
        case CWEventTypeRangingReportEvent:
            return @"WiFi Ranging Measurement Completed";
        case CWEventTypeUnknown:
            return @"Unknown";
    }
}
NSString *WiFiDescriptionForBOOL(BOOL boolValue){
    return boolValue ? @"YES" : @"NO";
}
NSString *WiFiDescriptionForCWChannel(CWChannel *channel){
    NSMutableArray *descArray = @[].mutableCopy;
    [descArray addObject:
     [NSString stringWithFormat:@"channelNumber:%ld",channel.channelNumber]];
    [descArray addObject:
     [NSString stringWithFormat:@"channelWidth:%@",NSStringFromCWChannelWidth(channel.channelWidth)]];
    [descArray addObject:
     [NSString stringWithFormat:@"channelBand:%@",NSStringFromCWChannelBand(channel.channelBand)]];
    NSString *description = [descArray componentsJoinedByString:@"\t\t"];
    return description;
}
NSString *WiFiDescriptionForCWInterface(CWInterface *interface){
    NSMutableArray *descArray = @[].mutableCopy;
    [descArray addObject:[NSString stringWithFormat:@"interfaceName:%@",interface.interfaceName]];
    [descArray addObject:[NSString stringWithFormat:@"powerOn:%@",WiFiDescriptionForBOOL(interface.powerOn)]];
    NSMutableArray<NSString *> *supportedWLANChannels = @[].mutableCopy;
    [interface.supportedWLANChannels enumerateObjectsUsingBlock:^(CWChannel * _Nonnull obj, BOOL * _Nonnull stop) {
        [supportedWLANChannels addObject:WiFiDescriptionForCWChannel(obj)];
    }];
    [descArray addObject:[NSString stringWithFormat:@"supportedWLANChannels:{\n%@\n}",[supportedWLANChannels componentsJoinedByString:@"\n"]]];
    [descArray addObject:[NSString stringWithFormat:@"wlanChannel:%@",WiFiDescriptionForCWChannel(interface.wlanChannel)]];
    [descArray addObject:[NSString stringWithFormat:@"activePHYMode:%@",NSStringFromCWPHYMode(interface.activePHYMode)]];
    [descArray addObject:[NSString stringWithFormat:@"ssid:%@",interface.ssid]];
    [descArray addObject:[NSString stringWithFormat:@"ssidData:%@",interface.ssidData]];
    [descArray addObject:[NSString stringWithFormat:@"bssid:%@",interface.bssid]];
    [descArray addObject:[NSString stringWithFormat:@"rssiValue:%ld dBm",interface.rssiValue]];
    [descArray addObject:[NSString stringWithFormat:@"noiseMeasurement:%ld dBm",interface.noiseMeasurement]];
    [descArray addObject:[NSString stringWithFormat:@"security:%@",NSStringFromCWSecurity(interface.security)]];
    [descArray addObject:[NSString stringWithFormat:@"transmitRate:%lf Mbps",interface.transmitRate]];
    [descArray addObject:[NSString stringWithFormat:@"countryCode:%@",interface.countryCode]];
    [descArray addObject:[NSString stringWithFormat:@"interfaceMode:%@",NSStringFromCWInterfaceMode(interface.interfaceMode)]];
    [descArray addObject:[NSString stringWithFormat:@"transmitPower:%ld mW",interface.transmitPower]];
    [descArray addObject:[NSString stringWithFormat:@"hardwareAddress:%@",interface.hardwareAddress]];
    [descArray addObject:[NSString stringWithFormat:@"serviceActive:%@",WiFiDescriptionForBOOL(interface.serviceActive)]];
    NSMutableArray<NSString *> *cachedScanResults = @[].mutableCopy;
    [interface.cachedScanResults enumerateObjectsUsingBlock:^(CWNetwork * _Nonnull obj, BOOL * _Nonnull stop) {
        [cachedScanResults addObject:WiFiDescriptionForCWNetwork(obj)];
    }];
    [descArray addObject:[NSString stringWithFormat:@"cachedScanResults:{\n%@\n}",[cachedScanResults componentsJoinedByString:@"\n"]]];
    [descArray addObject:[NSString stringWithFormat:@"configuration:%@",WiFiDescriptionForCWConfiguration(interface.configuration)]];
    NSString *description = [descArray componentsJoinedByString:@"\n"];
    return description;
}
NSString *WiFiDescriptionForCWNetwork(CWNetwork *network){
    NSMutableArray *descArray = @[].mutableCopy;
    [descArray addObject:[NSString stringWithFormat:@"ssid:%@",network.ssid]];
    [descArray addObject:[NSString stringWithFormat:@"ssidData:%@",network.ssidData]];
    [descArray addObject:[NSString stringWithFormat:@"bssid:%@",network.bssid]];
    [descArray addObject:[NSString stringWithFormat:@"wlanChannel:%@",WiFiDescriptionForCWChannel(network.wlanChannel)]];
    [descArray addObject:[NSString stringWithFormat:@"rssiValue:%ld",network.rssiValue]];
    [descArray addObject:[NSString stringWithFormat:@"noiseMeasurement:%ld",network.noiseMeasurement]];
    [descArray addObject:[NSString stringWithFormat:@"informationElementData:%@",network.informationElementData]];
    [descArray addObject:[NSString stringWithFormat:@"countryCode:%@",network.countryCode]];
    [descArray addObject:[NSString stringWithFormat:@"beaconInterval:%ld",network.beaconInterval]];
    [descArray addObject:[NSString stringWithFormat:@"ibss:%@",WiFiDescriptionForBOOL(network.ibss)]];
    NSMutableArray<NSString *> *supportedSecurities = @[].mutableCopy;
    NSInteger securities[10] = {kCWSecurityWEP,
                                kCWSecurityWPAPersonal,
                                kCWSecurityWPAPersonalMixed,
                                kCWSecurityWPA2Personal,
                                kCWSecurityPersonal,
                                kCWSecurityDynamicWEP,
                                kCWSecurityWPAEnterprise,
                                kCWSecurityWPAEnterpriseMixed,
                                kCWSecurityWPA2Enterprise,
                                kCWSecurityEnterprise};
    for (int i = 0; i < 10; i++) {
        CWSecurity security = securities[i];
        if ([network supportsSecurity:security]) {
            [supportedSecurities addObject:NSStringFromCWSecurity(security)];
        }
    }
    [descArray addObject:[NSString stringWithFormat:@"supportedSecurity:{\n%@\n}",[supportedSecurities componentsJoinedByString:@"\n"]]];
    NSInteger phyModes[10] = {kCWPHYMode11a,kCWPHYMode11b,kCWPHYMode11g,kCWPHYMode11n,kCWPHYMode11ac};
    NSMutableArray<NSString *> *supportedPHYModes = @[].mutableCopy;
    for (int i = 0; i < 10; i++) {
        CWPHYMode phyMode = phyModes[i];
        if ([network supportsPHYMode:phyMode]) {
            [supportedPHYModes addObject:NSStringFromCWPHYMode(phyMode)];
        }
    }
    [descArray addObject:[NSString stringWithFormat:@"supportedPHYModes:{\n%@\n}",[supportedPHYModes componentsJoinedByString:@"\n"]]];
    NSString *description = [descArray componentsJoinedByString:@"\n"];
    return description;
}
NSString *WiFiDescriptionForCWNetworkProfile(CWNetworkProfile *profile){
    NSMutableArray *descArray = @[].mutableCopy;
    [descArray addObject:
     [NSString stringWithFormat:@"ssid:%@",profile.ssid]];
    [descArray addObject:
     [NSString stringWithFormat:@"ssidData:%@",profile.ssidData]];
    [descArray addObject:
     [NSString stringWithFormat:@"security:%@",NSStringFromCWSecurity(profile.security)]];
    NSString *description = [descArray componentsJoinedByString:@"\n"];
    return description;
}
NSString *WiFiDescriptionForCWConfiguration(CWConfiguration *configuration){
    NSMutableArray *descArray = @[].mutableCopy;
    NSMutableArray<NSString *> *networkProfiles = @[].mutableCopy;
    for (CWNetworkProfile *obj in configuration.networkProfiles) {
        [networkProfiles addObject:WiFiDescriptionForCWNetworkProfile(obj)];
    }
    [descArray addObject:[NSString stringWithFormat:@"networkProfiles:{\n%@\n}",[networkProfiles componentsJoinedByString:@"\n"]]];
    [descArray addObject:[NSString stringWithFormat:@"requireAdministratorForAssociation:%@",WiFiDescriptionForBOOL(configuration.requireAdministratorForAssociation)]];
    [descArray addObject:[NSString stringWithFormat:@"requireAdministratorForPower:%@",WiFiDescriptionForBOOL(configuration.requireAdministratorForPower)]];
    [descArray addObject:[NSString stringWithFormat:@"requireAdministratorForIBSSMode:%@",WiFiDescriptionForBOOL(configuration.requireAdministratorForIBSSMode)]];
    [descArray addObject:[NSString stringWithFormat:@"rememberJoinedNetworks:%@",WiFiDescriptionForBOOL(configuration.rememberJoinedNetworks)]];
    NSString *description = [descArray componentsJoinedByString:@"\n"];
    return description;
}
#endif
