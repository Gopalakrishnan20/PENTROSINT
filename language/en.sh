#!/usr/bin/env bash
# English
# native: English

PENTInterfaceQuery="Select a wireless interface"
PENTAllocatingInterfaceNotice="Allocating reserved interface $CGrn\"\$interfaceIdentifier\"."
PENTDeallocatingInterfaceNotice="Deallocating reserved interface $CGrn\"\$interfaceIdentifier\"."
PENTInterfaceAllocatedNotice="${CGrn}Interface allocation succeeded!"
PENTInterfaceAllocationFailedError="${CRed}Interface reservation failed!"
PENTReidentifyingInterface="Renaming interface."
PENTUnblockingWINotice="Unblocking all wireless interfaces."
#PENTFindingExtraWINotice="Looking for extraneous wireless interfaces..."
PENTRemovingExtraWINotice="Removing extraneous wireless interfaces..."
PENTFindingWINotice="Looking for available wireless interfaces..."
PENTSelectedBusyWIError="The wireless interface selected appears to be currently in use!"
PENTSelectedBusyWITip="This is usually caused by the network manager using the interface selected. We recommened you$CGrn gracefully stop the network manager$CClr or configure it to ignored the selected interface. Alternatively, run \"export PENTWIKillProcesses=1\" before wifipot to kill it but we suggest you$CRed avoid using the killer flag${CClr}."
PENTGatheringWIInfoNotice="Gathering interface information..."
PENTUnknownWIDriverError="Unable to determine interface driver!"
PENTUnloadingWIDriverNotice="Waiting for interface \"\$interface\" to unload..."
PENTLoadingWIDriverNotice="Waiting for interface \"\$interface\" to load..."
PENTFindingConflictingProcessesNotice="Looking for notorious services..."
PENTKillingConflictingProcessesNotice="Killing notorious services..."
PENTPhysicalWIDeviceUnknownError="${CRed}Unable to determine interface's physical device!"
PENTStartingWIMonitorNotice="Starting monitor interface..."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTTargetSearchingInterfaceQuery="Select a wireless interface for target searching."
PENTTargetTrackerInterfaceQuery="Select a wireless interface for target tracking."
PENTTargetTrackerInterfaceQueryTip="${CSYel}Choosing a dedicated interface may be required.$CClr"
PENTTargetTrackerInterfaceQueryTip2="${CBRed}If you're unsure, choose \"${CBYel}Skip${CBRed}\"!$CClr"
PENTIncompleteTargettingInfoNotice="Missing ESSID, BSSID, or channel information!"
PENTTargettingAccessPointAboveNotice="Wifipot is targetting the access point above."
PENTContinueWithTargetQuery="Continue with this target?"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTStartingScannerNotice="Starting scanner, please wait..."
PENTStartingScannerTip="Five seconds after the target AP appears, close the WIFIPOT Scanner (ctrl+c)."
PENTPreparingScannerResultsNotice="Synthesizing scan results, please wait..."
PENTScannerFailedNotice="Wireless card may not be supported (no APs found)"
PENTScannerDetectedNothingNotice="No access points were detected, returning..."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTHashFileDoesNotExistError="Hash file does not exist!"
PENTHashInvalidError="${CRed}Error$CClr, invalid hash file!"
PENTHashValidNotice="${CGrn}Success$CClr, hash verification completed!"
PENTPathToHandshakeFileQuery="Enter path to handshake file $CClr(Example: /path/to/file.cap)"
PENTPathToHandshakeFileReturnTip="To go back, leave the hash path blank."
PENTAbsolutePathInfo="Absolute path"
PENTEmptyOrNonExistentHashError="${CRed}Error$CClr, path points to non-existing or empty hash file."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTScannerChannelQuery="Select a channel to monitor"
PENTScannerChannelOptionAll="All channels"
PENTScannerChannelOptionSpecific="Specific channel(s)"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTScannerChannelSingleTip="Single channel"
PENTScannerChannelMiltipleTip="Multiple channels"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTScannerHeader="PENT Scanner"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTHashSourceQuery="Select a method to retrieve the handshake"
PENTHashSourcePathOption="Path to capture file"
PENTHashSourceRescanOption="Rescan handshake directory"
PENTFoundHashNotice="A hash for the target AP was found."
PENTUseFoundHashQuery="Do you want to use this file?"
PENTUseFoundHashOption="Use hash found"
PENTSpecifyHashPathOption="Specify path to hash"
PENTHashVerificationMethodQuery="Select a method of verification for the hash"
PENTHashVerificationMethodPyritOption="pyrit verification"
PENTHashVerificationMethodAircrackOption="aircrack-ng verification (${CYel}unreliable$CClr)"
PENTHashVerificationMethodCowpattyOption="cowpatty verification (${CGrn}recommended$CClr)"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTAttackQuery="Select a wireless attack for the access point"
PENTAttackInProgressNotice="${CCyn}\$Wifipot Attack$CClr attack in progress..."
PENTSelectAnotherAttackOption="Select another attack"
PENTAttackResumeQuery="This attack has already been configured."
PENTAttackRestoreOption="Restore attack"
PENTAttackResetOption="Reset attack"
PENTAttackRestartOption="Restart"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTGeneralSkipOption="${CYel}Skip"
PENTGeneralBackOption="${CRed}Back"
PENTGeneralExitOption="${CRed}Exit"
PENTGeneralRepeatOption="${CRed}Repeat"
PENTGeneralNotFoundError="Not Found"
PENTGeneralXTermFailureError="${CRed}Failed to start xterm session (possible misconfiguration)."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PENTCleanupAndClosingNotice="Cleaning and closing"
PENTKillingProcessNotice="Killing ${CGry}\$targetID$CClr"
PENTRestoringPackageManagerNotice="Restoring ${CCyn}\$PackageManagerCLT$CClr"
PENTDisablingMonitorNotice="Disabling monitoring interface"
PENTDisablingExtraInterfacesNotice="Disabling extra interfaces"
PENTDisablingPacketForwardingNotice="Disabling ${CGry}forwarding of packets"
PENTDisablingCleaningIPTablesNotice="Cleaning ${CGry}iptables"
PENTRestoringTputNotice="Restoring ${CGry}tput"
PENTDeletingFilesNotice="Deleting ${CGry}files"
PENTRestartingNetworkManagerNotice="Restarting ${CGry}Network-Manager"
PENTCleanupSuccessNotice="Cleanup performed successfully!"
PENTThanksSupportersNotice="Thank you for using PENT"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# FLUXSCRIPT END
