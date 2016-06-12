//
//  IJTAddFirewallTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/6/30.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAddFirewallTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTTCPFlagsTableViewCell.h"

@interface IJTAddFirewallTableViewController ()

@property (nonatomic, strong) FUISegmentedControl *actionSegmentedControl;
@property (nonatomic, strong) FUISegmentedControl *directionSegmentedControl;
@property (nonatomic, strong) FUISwitch *quickSwitch;
@property (nonatomic, strong) FUISegmentedControl *interfaceSegmentedControl;
@property (nonatomic, strong) FUISwitch *keepStateSwitch;
@property (nonatomic, strong) FUITextField *srcIpAddrTextField;
@property (nonatomic, strong) FUITextField *srcIpMaskTextField;
@property (nonatomic, strong) FUITextField *dstIpAddrTextField;
@property (nonatomic, strong) FUITextField *dstIpMaskTextField;
@property (nonatomic, strong) FUISegmentedControl *protocolSegmentedControl;
@property (nonatomic, strong) FUITextField *srcPortTextField;
@property (nonatomic, strong) FUITextField *dstPortTextField;
@property (nonatomic, strong) FUITextField *typeTextField;
@property (nonatomic, strong) FUITextField *codeTextField;
@property (nonatomic, strong) NSMutableDictionary *tcpFlagsButtonsBoolean;
@property (nonatomic, strong) NSMutableDictionary *tcpFlagsSetButtonsBoolean;
@property (nonatomic, strong) NSArray *tcpFlagsString;
@property (nonatomic, strong) FUIButton *addButton;

@end

@implementation IJTAddFirewallTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"down.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.actionSegmentedControl = [[FUISegmentedControl alloc]
                                   initWithFrame:CGRectMake(0, 0, 200, 28)];
    [self.actionSegmentedControl insertSegmentWithTitle:@"Allow" atIndex:0 animated:NO];
    [self.actionSegmentedControl insertSegmentWithTitle:@"Block" atIndex:1 animated:NO];
    [self.actionSegmentedControl setSelectedSegmentIndex:1];
    
    
    self.directionSegmentedControl = [[FUISegmentedControl alloc]
                                      initWithFrame:CGRectMake(0, 0, 200, 28)];
    [self.directionSegmentedControl insertSegmentWithTitle:@"In" atIndex:0 animated:NO];
    [self.directionSegmentedControl insertSegmentWithTitle:@"Out" atIndex:1 animated:NO];
    [self.directionSegmentedControl insertSegmentWithTitle:@"In/Out" atIndex:2 animated:NO];
    [self.directionSegmentedControl setSelectedSegmentIndex:2];
    
    self.quickSwitch = [[FUISwitch alloc]
                        initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.quickSwitch.onLabel.text = @"YES";
    self.quickSwitch.offLabel.text = @"NO";
    self.quickSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.quickSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    
    self.interfaceSegmentedControl = [[FUISegmentedControl alloc]
                                      initWithFrame:CGRectMake(0, 0, 150, 28)];
    
    BOOL supportWifi, supportCellular;
    supportWifi = [IJTNetowrkStatus supportWifi];
    supportCellular = [IJTNetowrkStatus supportCellular];
    
    if(supportWifi) {
        [self.interfaceSegmentedControl insertSegmentWithTitle:@"Wi-Fi" atIndex:0 animated:NO];
        [self.interfaceSegmentedControl setEnabled:YES forSegmentAtIndex:0];
    }
    if(supportCellular) {
        [self.interfaceSegmentedControl insertSegmentWithTitle:@"Cellular" atIndex:1 animated:NO];
        [self.interfaceSegmentedControl setEnabled:YES forSegmentAtIndex:1];
    }
    if(supportWifi) {
        [self.interfaceSegmentedControl setSelectedSegmentIndex:0];
    }
    else if(supportCellular) {
        [self.interfaceSegmentedControl setSelectedSegmentIndex:1];
    }
    
    if(!supportCellular && !supportWifi) {
        [self.interfaceSegmentedControl setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self showErrorMessage:@"There is no network interface available."];
        }];
    }
    
    
    self.keepStateSwitch = [[FUISwitch alloc]
                            initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.keepStateSwitch.onLabel.text = @"YES";
    self.keepStateSwitch.offLabel.text = @"NO";
    self.keepStateSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.keepStateSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.keepStateSwitch setOn:NO];
    
    
    self.srcIpAddrTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.srcIpAddrTextField.placeholder = @"Source IP address or any";
    [self.srcIpAddrTextField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    
    
    self.srcIpMaskTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.srcIpMaskTextField.placeholder = @"Source netmask or any";
    [self.srcIpMaskTextField addTarget:self
                                action:@selector(textFieldDidChange:)
                      forControlEvents:UIControlEventEditingChanged];
    
    
    self.dstIpAddrTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.dstIpAddrTextField.placeholder = @"Destination IP address or any";
    [self.dstIpAddrTextField addTarget:self
                                action:@selector(textFieldDidChange:)
                      forControlEvents:UIControlEventEditingChanged];
    
    
    self.dstIpMaskTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.dstIpMaskTextField.placeholder = @"Destination netmask or any";
    self.dstIpMaskTextField.returnKeyType = UIReturnKeyDone;
    [self.dstIpMaskTextField addTarget:self
                                action:@selector(textFieldDidChange:)
                      forControlEvents:UIControlEventEditingChanged];
    
    
    self.protocolSegmentedControl = [[FUISegmentedControl alloc]
                                     initWithFrame:CGRectMake(0, 0, 220, 28)];
    [self.protocolSegmentedControl insertSegmentWithTitle:@"IP" atIndex:0 animated:NO];
    [self.protocolSegmentedControl insertSegmentWithTitle:@"TCP" atIndex:1 animated:NO];
    [self.protocolSegmentedControl insertSegmentWithTitle:@"UDP" atIndex:2 animated:NO];
    [self.protocolSegmentedControl insertSegmentWithTitle:@"ICMP" atIndex:3 animated:NO];
    [self.protocolSegmentedControl setSelectedSegmentIndex:0];
    [self.protocolSegmentedControl
     addTarget:self
     action:@selector(protocolSegmentedControlValueChanged:)
     forControlEvents:UIControlEventValueChanged];
    
    
    self.srcPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.srcPortTextField.placeholder = @"Source port or port-port";
    
    
    self.dstPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.dstPortTextField.placeholder = @"Destination port or port-port";
    self.dstPortTextField.returnKeyType = UIReturnKeyDone;
    
    
    self.typeTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.typeTextField.placeholder = @"ICMP type";
    
    
    self.codeTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.codeTextField.placeholder = @"ICMP code";
    self.codeTextField.returnKeyType = UIReturnKeyDone;
    
    self.tcpFlagsString = @[@"FIN", @"SYN", @"RST", @"PUSH", @"ACK", @"URG", @"ECE", @"CWR"];
    self.tcpFlagsButtonsBoolean = [[NSMutableDictionary alloc] init];
    self.tcpFlagsSetButtonsBoolean = [[NSMutableDictionary alloc] init];
    
    for(NSString *s in self.tcpFlagsString) {
        [self.tcpFlagsButtonsBoolean setObject:@(NO) forKey:s];
        [self.tcpFlagsSetButtonsBoolean setObject:@(NO) forKey:s];
    }
    
    self.addButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.addButton setTitle:@"New one" forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addRule) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self dismissKeyboard];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissKeyboard {
    if(self.srcIpAddrTextField.isFirstResponder) {
        [self.srcIpAddrTextField resignFirstResponder];
    }
    else if(self.srcIpMaskTextField.isFirstResponder) {
        [self.srcIpMaskTextField resignFirstResponder];
    }
    else if(self.dstIpAddrTextField.isFirstResponder) {
        [self.dstIpAddrTextField resignFirstResponder];
    }
    else if(self.dstIpMaskTextField.isFirstResponder) {
        [self.dstIpMaskTextField resignFirstResponder];
    }
    else if(self.srcPortTextField.isFirstResponder) {
        [self.srcPortTextField resignFirstResponder];
    }
    else if(self.dstPortTextField.isFirstResponder) {
        [self.dstPortTextField resignFirstResponder];
    }
    else if(self.typeTextField.isFirstResponder) {
        [self.typeTextField resignFirstResponder];
    }
    else if(self.codeTextField.isFirstResponder) {
        [self.codeTextField resignFirstResponder];
    }
}

- (void)addRule {
    [self dismissKeyboard];
    
    //check ip
    if(_srcIpAddrTextField.text.length <= 0) {
        [self showErrorMessage:@"Source IP address is empty."];
        return;
    }
    else {
        if(![_srcIpAddrTextField.text isEqualToString:@"any"] &&
           ![IJTValueChecker checkIpv4Address:_srcIpAddrTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid IP address.",
              _srcIpAddrTextField.text]];
            return;
        }
    }
    if(_srcIpMaskTextField.text.length <= 0) {
        [self showErrorMessage:@"Source IP mask is empty."];
        return;
    }
    else {
        if(![_srcIpMaskTextField.text isEqualToString:@"any"] &&
           ![IJTValueChecker checkNetmask:_srcIpMaskTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid netmask address.",
              _srcIpMaskTextField.text]];
            return;
        }
    }
    if(_dstIpAddrTextField.text.length <= 0) {
        [self showErrorMessage:@"Destination IP address is empty."];
        return;
    }
    else {
        if(![_dstIpAddrTextField.text isEqualToString:@"any"] &&
           ![IJTValueChecker checkIpv4Address:_dstIpAddrTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid IP address.",
              _dstIpAddrTextField.text]];
            return;
        }
    }
    if(_dstIpMaskTextField.text.length <= 0) {
        [self showErrorMessage:@"Destination IP mask is empty."];
        return;
    }
    else {
        if(![_dstIpMaskTextField.text isEqualToString:@"any"] &&
           ![IJTValueChecker checkNetmask:_dstIpMaskTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid netmask address.",
              _dstIpMaskTextField.text]];
            return;
        }
    }
    
    if(([_srcIpAddrTextField.text isEqualToString:@"any"] &&
        ![_srcIpMaskTextField.text isEqualToString:@"any"]) ||
       (![_srcIpAddrTextField.text isEqualToString:@"any"] &&
        [_srcIpMaskTextField.text isEqualToString:@"any"])) {
           [self showErrorMessage:@"One of source parameter can\'t be \"any\""];
           return;
    }
    if(([_dstIpAddrTextField.text isEqualToString:@"any"] &&
        ![_dstIpMaskTextField.text isEqualToString:@"any"]) ||
       (![_dstIpAddrTextField.text isEqualToString:@"any"] &&
        [_dstIpMaskTextField.text isEqualToString:@"any"])) {
           [self showErrorMessage:@"One of destination parameter can\'t be \"any\""];
           return;
       }
    
    //check port
    if(self.protocolSegmentedControl.selectedSegmentIndex == 1 ||
       self.protocolSegmentedControl.selectedSegmentIndex == 2) {
        if(_srcPortTextField.text.length <= 0) {
            [self showErrorMessage:@"Source port is empty."];
            return;
        }
        else {
            if(![IJTValueChecker checkPortWithRange:_srcPortTextField.text] &&
               ![IJTValueChecker checkPort:_srcPortTextField.text]) {
                [self showErrorMessage:
                 [NSString stringWithFormat:@"\"%@\" is not a valid port number or format.",
                                        _srcPortTextField.text]];
                return;
            }
        }
        if(_dstPortTextField.text.length <= 0) {
            [self showErrorMessage:@"Destination port is empty."];
            return;
        }
        else {
            if(![IJTValueChecker checkPortWithRange:_dstPortTextField.text] &&
               ![IJTValueChecker checkPort:_dstPortTextField.text]) {
                [self showErrorMessage:
                 [NSString stringWithFormat:@"\"%@\" is not a valid port number or format.",
                  _dstPortTextField.text]];
                return;
            }
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) { //check icmp
        if(_typeTextField.text.length <= 0) {
            [self showErrorMessage:@"Type is empty."];
            return;
        }
        else if(![IJTValueChecker checkUint8:_typeTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid type.",
              _typeTextField.text]];
            return;
        }
        if(_codeTextField.text.length <= 0) {
            [self showErrorMessage:@"Code is empty."];
            return;
        }
        else if(![IJTValueChecker checkUint8:_codeTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid code.",
              _codeTextField.text]];
            return;
        }
    }
    
    IJTFirewallOperator action;
    IJTFirewallDirection direction;
    BOOL quick;
    NSString *interface = @"";
    BOOL keepState;
    NSString *srcIpAddress = @"", *srcMaskIpAddress = @"";
    NSString *dstIpAddress = @"", *dstMaskIpAddress = @"";
    u_int16_t srcStartPort = 0, srcEndPort = 0;
    u_int16_t dstStartPort = 0, dstEndPort = 0;
    BOOL srcPortRange, dstPortRange;
    IJTFirewallTCPFlag tcpFlags = 0, tcpFlagsSet = 0;
    u_int8_t type = 0, code = 0;
    
    if(self.actionSegmentedControl.selectedSegmentIndex == 0)
        action = IJTFirewallOperatorAllow;
    else
        action = IJTFirewallOperatorBlock;
    
    if(self.directionSegmentedControl.selectedSegmentIndex == 0)
        direction = IJTFirewallDirectionIn;
    else if(self.directionSegmentedControl.selectedSegmentIndex == 1)
        direction = IJTFirewallDirectionOut;
    else
        direction = IJTFirewallDirectionInAndOut;
    
    quick = self.quickSwitch.isOn;
    
    if(self.interfaceSegmentedControl.selectedSegmentIndex == 0)
        interface = @"en0";
    else
        interface = @"pdp_ip0";
    
    keepState = self.keepStateSwitch.isOn;
    
    if([self.srcIpAddrTextField.text isEqualToString:@"any"])
        srcIpAddress = @"0.0.0.0";
    else
        srcIpAddress = self.srcIpAddrTextField.text;
    if([self.srcIpMaskTextField.text isEqualToString:@"any"])
        srcMaskIpAddress = @"0.0.0.0";
    else
        srcMaskIpAddress = self.srcIpMaskTextField.text;
    
    if([self.dstIpAddrTextField.text isEqualToString:@"any"])
        dstIpAddress = @"0.0.0.0";
    else
        dstIpAddress = self.dstIpAddrTextField.text;
    if([self.dstIpMaskTextField.text isEqualToString:@"any"])
        dstMaskIpAddress = @"0.0.0.0";
    else
        dstMaskIpAddress = self.dstIpMaskTextField.text;
    
    if(getegid())
        return;
    
    IJTFirewall *fw = [[IJTFirewall alloc] init];
    if(fw.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
        
        [fw close];
        fw = nil;
        return;
    }
    
    if(self.protocolSegmentedControl.selectedSegmentIndex == 0) {
        [fw addRuleAtInterface:interface
                            op:action
                           dir:direction
                        family:AF_INET
                       srcAddr:srcIpAddress
                       dstAddr:dstIpAddress
                       srcMask:srcMaskIpAddress
                       dstMask:dstMaskIpAddress
                     keepState:keepState
                         quick:quick];
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1) {
        [self getPort:_srcPortTextField.text
                start:&srcStartPort
                  end:&srcEndPort
                range:&srcPortRange];
        [self getPort:_dstPortTextField.text
                start:&dstStartPort
                  end:&dstEndPort
                range:&dstPortRange];
        
        NSNumber *selectedFlags, *selectedFlagsSet;
        for(NSString *flags in self.tcpFlagsString) {
            selectedFlags = [self.tcpFlagsButtonsBoolean valueForKey:flags];
            selectedFlagsSet = [self.tcpFlagsSetButtonsBoolean valueForKey:flags];
            if([flags isEqualToString:@"FIN"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagFIN;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagFIN;
                }
            }
            else if([flags isEqualToString:@"SYN"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagSYN;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagSYN;
                }
            }
            else if([flags isEqualToString:@"RST"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagRST;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagRST;
                }
            }
            else if([flags isEqualToString:@"PUSH"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagPUSH;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagPUSH;
                }
            }
            else if([flags isEqualToString:@"ACK"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagACK;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagACK;
                }
            }
            else if([flags isEqualToString:@"URG"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagURG;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagURG;
                }
            }
            else if([flags isEqualToString:@"ECE"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagECE;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagECE;
                }
            }
            else if([flags isEqualToString:@"CWR"]) {
                if([selectedFlags boolValue]) {
                    tcpFlags |= IJTFirewallTCPFlagCWR;
                }
                if([selectedFlagsSet boolValue]) {
                    tcpFlagsSet |= IJTFirewallTCPFlagCWR;
                }
            }
        }
        
        if(srcPortRange && dstPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolTCP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                              srcStartPort:srcStartPort
                                srcEndPort:srcEndPort
                              dstStartPort:dstStartPort
                                dstEndPort:dstEndPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else if(srcPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolTCP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                              srcStartPort:srcStartPort
                                srcEndPort:srcEndPort
                                   dstPort:dstStartPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else if(dstPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolTCP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                                   srcPort:srcStartPort
                              dstStartPort:dstStartPort
                                dstEndPort:dstEndPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolTCP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                                   srcPort:srcStartPort
                                   dstPort:dstStartPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 2) {
        [self getPort:_srcPortTextField.text
                start:&srcStartPort
                  end:&srcEndPort
                range:&srcPortRange];
        [self getPort:_dstPortTextField.text
                start:&dstStartPort
                  end:&dstEndPort
                range:&dstPortRange];
        
        if(srcPortRange && dstPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolUDP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                              srcStartPort:srcStartPort
                                srcEndPort:srcEndPort
                              dstStartPort:dstStartPort
                                dstEndPort:dstEndPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else if(srcPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolUDP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                              srcStartPort:srcStartPort
                                srcEndPort:srcEndPort
                                   dstPort:dstStartPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else if(dstPortRange) {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolUDP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                                   srcPort:srcStartPort
                              dstStartPort:dstStartPort
                                dstEndPort:dstEndPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        else {
            [fw addTCPOrUDPRuleAtInterface:interface
                                        op:action
                                       dir:direction
                                     proto:IJTFirewallProtocolUDP
                                    family:AF_INET
                                   srcAddr:srcIpAddress
                                   dstAddr:dstIpAddress
                                   srcMask:srcMaskIpAddress
                                   dstMask:dstMaskIpAddress
                                   srcPort:srcStartPort
                                   dstPort:dstStartPort
                                  tcpFlags:tcpFlags
                              tcpFlagsMask:tcpFlagsSet
                                 keepState:keepState quick:quick];
        }
        
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) {
        type = [self.typeTextField.text intValue];
        code = [self.codeTextField.text intValue];
        
        [fw addICMPRuleAtInterface:interface
                                op:action
                               dir:direction
                           srcAddr:srcIpAddress
                           dstAddr:dstIpAddress
                           srcMask:srcMaskIpAddress
                           dstMask:dstMaskIpAddress
                          icmpType:type
                          icmpCode:code
                         keepState:keepState
                             quick:quick];
    }
    
    if(fw.errorHappened) {
        if(fw.errorCode == EEXIST) {
            [self showErrorMessage:@"The Rule is exsit."];
        }
        else {
            [self showErrorMessage:
             [NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
        }
    }
    else {
        [self showSuccessMessage:@"Success"];
        [self.delegate callback];
    }
    
    [fw close];
    fw = nil;
    return;
}

- (void)getPort: (NSString *)portString start: (u_int16_t *)start end: (u_int16_t *)end range: (BOOL *)range {
    if([IJTValueChecker checkPortWithRange:portString]) {
        NSArray *array = [portString componentsSeparatedByString:@"-"];
        if(array.count == 1) {
            NSString *first = array[0];
            *start = [first intValue];
            *end = 0;
            *range = NO;
            return;
        }
        else if(array.count == 2) {
            NSString *first = array[0];
            NSString *second = array[1];
            
            *start = [first intValue];
            *end = [second intValue];
            *range = YES;
        }
        else {
            *start = *end = 0;
            *range = NO;
            return;
        }
    }
    else if([IJTValueChecker checkPort:portString]) {
        *start = [portString intValue];
        *end = 0;
        *range = NO;
    }
    else {
        *range = NO;
        *start = *end = 0;
    }
}

#pragma mark segmented control delegate
- (void)protocolSegmentedControlValueChanged: (id)sender {
    [self.tableView reloadData];
    
    if(self.protocolSegmentedControl.selectedSegmentIndex != 0)
        self.dstIpMaskTextField.returnKeyType = UIReturnKeyNext;
    else
        self.dstIpMaskTextField.returnKeyType = UIReturnKeyDone;
    
    self.srcPortTextField.text = @"";
    self.dstPortTextField.text = @"";
    self.typeTextField.text = @"";
    self.codeTextField.text = @"";
    self.tcpFlagsButtonsBoolean = [[NSMutableDictionary alloc] init];
    self.tcpFlagsSetButtonsBoolean = [[NSMutableDictionary alloc] init];
    
    for(NSString *s in self.tcpFlagsString) {
        [self.tcpFlagsButtonsBoolean setObject:@(NO) forKey:s];
        [self.tcpFlagsSetButtonsBoolean setObject:@(NO) forKey:s];
    }
    
    if(self.protocolSegmentedControl.selectedSegmentIndex == 3) { //icmp
        if(!self.keepStateSwitch.isOn) {
            [self showInfoMessage:@"ICMP must be keep state."];
            //[self showInformationMessageOneOrNot:@"ICMP must be keep state." key:@"ShowICMPKeepStateInformation"];
        }
        [self.keepStateSwitch setOn:YES animated:YES];
        [self.keepStateSwitch setEnabled:NO];
    }
    else {
        [self.keepStateSwitch setEnabled:YES];
    }
}

#pragma mark tcp flags button
- (void)tcpFlagsButton: (id)sender {
    UIButton *button = (UIButton *)sender;
    NSMutableDictionary *dict = nil;
    if(button.tag == 2) {
        dict = self.tcpFlagsButtonsBoolean;
    }
    else if(button.tag == 3) {
        dict = self.tcpFlagsSetButtonsBoolean;
    }
    
    for(NSString *flags in self.tcpFlagsString) {
        if([button.titleLabel.text isEqualToString:flags]) {
            NSNumber *selected = [dict valueForKey:flags];
            selected = [NSNumber numberWithBool:![selected boolValue]];
            [dict setObject:selected forKey:flags];
        }
    }
}

#pragma mark text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.srcIpAddrTextField) {
        [self.srcIpMaskTextField becomeFirstResponder];
    }
    else if(textField == self.srcIpMaskTextField) {
        [self.dstIpAddrTextField becomeFirstResponder];
    }
    else if(textField == self.dstIpAddrTextField) {
        [self.dstIpMaskTextField becomeFirstResponder];
    }
    else if(textField == self.dstIpMaskTextField) {
        if(self.protocolSegmentedControl.selectedSegmentIndex == 1 ||
           self.protocolSegmentedControl.selectedSegmentIndex == 2) {
            [self.srcPortTextField becomeFirstResponder];
        }
        else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) {
            [self.typeTextField becomeFirstResponder];
        }
        else {
            [self.dstIpMaskTextField resignFirstResponder];
        }
    }
    else if(textField == self.srcPortTextField) {
        [self.dstPortTextField becomeFirstResponder];
    }
    else if(textField == self.dstPortTextField) {
        [self.dstPortTextField resignFirstResponder];
    }
    else if(textField == self.typeTextField) {
        [self.codeTextField becomeFirstResponder];
    }
    else if(textField == self.codeTextField) {
        [self.codeTextField resignFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidChange:(id)sender {
    FUITextField *textField = (FUITextField *)sender;
    
    if(textField == self.srcIpAddrTextField) {
        if([self.srcIpAddrTextField.text isEqualToString:@"any"]) {
            self.srcIpMaskTextField.text = @"any";
        }
    }
    else if(textField == self.srcIpMaskTextField) {
        if([self.srcIpMaskTextField.text isEqualToString:@"any"]) {
            self.srcIpAddrTextField.text = @"any";
        }
    }
    else if(textField == self.dstIpAddrTextField) {
        if([self.dstIpAddrTextField.text isEqualToString:@"any"]) {
            self.dstIpMaskTextField.text = @"any";
        }
    }
    else if(textField == self.dstIpMaskTextField) {
        if([self.dstIpMaskTextField.text isEqualToString:@"any"]) {
            self.dstIpAddrTextField.text = @"any";
        }
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.srcIpAddrTextField || textField == self.srcIpMaskTextField ||
       textField == self.dstIpAddrTextField || textField == self.dstIpMaskTextField) {
        
        allowString = @"1234567890.any\b";
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1 || self.protocolSegmentedControl.selectedSegmentIndex == 2) {
        if(textField == self.srcPortTextField || textField == self.dstPortTextField) {
            allowString = @"1234567890-\b";
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) {
        if(textField == self.codeTextField || textField == self.typeTextField) {
            allowString = @"1234567890\b";
        }
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Base Parameters";
    }
    
    if(self.protocolSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return @"New one";
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 1) {
            return @"TCP port";
        }
        else if(section == 2) {
            return @"TCP flags";
        }
        else if(section == 3) {
            return @"TCP flags set";
        }
        else if(section == 4) {
            return @"New one";
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 1) {
            return @"UDP port";
        }
        else if(section == 2) {
            return @"New one";
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) {
        if(section == 1) {
            return @"ICMP State";
        }
        else if(section == 2) {
            return @"New one";
        }
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(self.protocolSegmentedControl.selectedSegmentIndex == 0) //ip: base rule
        return 2;
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1)//tcp: base, port, flags, flags set
        return 5;
    else
        return 3;//udp: base, port, icmp: base, code/type
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 10;
    if(self.protocolSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return 1;
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 1) {
            return 2;
        }
        else if(section == 2) {
            return 1;
        }
        else if(section == 3) {
            return 1;
        }
        else if(section == 4) {
            return 1;
        }
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 2 || self.protocolSegmentedControl.selectedSegmentIndex == 3) {
        if(section == 1) {
            return 2;
        }
        else if(section == 2) {
            return 1;
        }
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0 &&
       ((indexPath.row >= 0 && indexPath.row <= 4) || indexPath.row == 9)) {
        GET_ARG_CELL;
        
        if(indexPath.section == 0) {
            switch (indexPath.row) {
                case 0:
                    cell.nameLabel.text = @"Action";
                    [cell.controlView addSubview:self.actionSegmentedControl];
                    break;
                    
                case 1:
                    cell.nameLabel.text = @"Direction";
                    [cell.controlView addSubview:self.directionSegmentedControl];
                    break;
                    
                case 2:
                    cell.nameLabel.text = @"Quick";
                    [cell.controlView addSubview:self.quickSwitch];
                    break;
                    
                case 3:
                    cell.nameLabel.text = @"Interface";
                    [cell.controlView addSubview:self.interfaceSegmentedControl];
                    break;
                    
                case 4:
                    cell.nameLabel.text = @"Keep State";
                    [cell.controlView addSubview:self.keepStateSwitch];
                    break;
                    
                case 9:
                    cell.nameLabel.text = @"Protocol";
                    [cell.controlView addSubview:self.protocolSegmentedControl];
                    break;
                    
                default: break;
            }
        }
        
        cell.nameLabel.font = [UIFont systemFontOfSize:17];
        
        [cell layoutIfNeeded];
        //realloc position
        CGFloat width = CGRectGetWidth(cell.controlView.frame);
        if(indexPath.section == 0) {
            switch (indexPath.row) {
                case 0: self.actionSegmentedControl.frame = CGRectMake(width - 200, 0, 200, 28); break;
                case 1: self.directionSegmentedControl.frame = CGRectMake(width - 200, 0, 200, 28); break;
                case 2: self.quickSwitch.frame = CGRectMake(width - 80, 0, 80, 28); break;
                case 3: self.interfaceSegmentedControl.frame = CGRectMake(width - 150, 0, 150, 28); break;
                case 4: self.keepStateSwitch.frame = CGRectMake(width - 80, 0, 80, 28); break;
                case 9: self.protocolSegmentedControl.frame = CGRectMake(0, 0, width, 28); break;
                default: break;
            }
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((indexPath.section == 0 && indexPath.row >= 5 && indexPath.row <= 8) ||
            ((self.protocolSegmentedControl.selectedSegmentIndex == 1 ||
              self.protocolSegmentedControl.selectedSegmentIndex == 2 ||
              self.protocolSegmentedControl.selectedSegmentIndex == 3) &&
             (indexPath.section == 1 && (indexPath.row == 0 || indexPath.row == 1)))) {
        GET_EMPTY_CELL;
                
        if(indexPath.section == 0) {
            switch (indexPath.row) {
                case 5: [cell.contentView addSubview:self.srcIpAddrTextField]; break;
                    
                case 6: [cell.contentView addSubview:self.srcIpMaskTextField]; break;
                    
                case 7: [cell.contentView addSubview:self.dstIpAddrTextField]; break;
                    
                case 8: [cell.contentView addSubview:self.dstIpMaskTextField]; break;
                    
                default: break;
            }
        }
        else if(indexPath.section == 1) {
            if(self.protocolSegmentedControl.selectedSegmentIndex == 1 ||
               self.protocolSegmentedControl.selectedSegmentIndex == 2) { //tcp, udp
                switch (indexPath.row) {
                    case 0: [cell.contentView addSubview:self.srcPortTextField]; break;
                    case 1: [cell.contentView addSubview:self.dstPortTextField]; break;
                    default: break;
                }
            }
            else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) { //icmp
                switch (indexPath.row) {
                    case 0: [cell.contentView addSubview:self.typeTextField]; break;
                    case 1: [cell.contentView addSubview:self.codeTextField]; break;
                    default: break;
                }
            }
        }
        [cell layoutIfNeeded];
        
        CGFloat height = CGRectGetHeight(cell.frame);
        if(indexPath.section == 0) {
            switch (indexPath.row) {
                case 5: self.srcIpAddrTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                case 6: self.srcIpMaskTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                case 7: self.dstIpAddrTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                case 8: self.dstIpMaskTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                default: break;
            }
        }
        else if(indexPath.section == 1) {
            if(self.protocolSegmentedControl.selectedSegmentIndex == 1 ||
               self.protocolSegmentedControl.selectedSegmentIndex == 2) { //tcp, udp
                switch (indexPath.row) {
                    case 0: self.srcPortTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                    case 1: self.dstPortTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                    default: break;
                }
            }
            else if(self.protocolSegmentedControl.selectedSegmentIndex == 3) {
                switch (indexPath.row) {
                    case 0: self.typeTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                    case 1: self.codeTextField.frame = CGRectMake(0, 0, SCREEN_WIDTH, height); break;
                    default: break;
                }
            }
        }
        return cell;
    }
    
    if((self.protocolSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 1) ||
       (self.protocolSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 4) ||
       (self.protocolSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 2) ||
       (self.protocolSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 2)) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddButtonCell" forIndexPath:indexPath];
        [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        CGFloat height = CGRectGetHeight(cell.frame);
        self.addButton.frame = CGRectMake(16, 8, SCREEN_WIDTH - 32, height - 16);
        [cell.contentView addSubview:self.addButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((indexPath.section == 2 || indexPath.section == 3) &&
            self.protocolSegmentedControl.selectedSegmentIndex == 1) { //tcp
        IJTTCPFlagsTableViewCell *cell = (IJTTCPFlagsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TCPFlagsCell" forIndexPath:indexPath];
        
        for(UIButton *button in cell.buttons) {
            button.tag = indexPath.section;
            [button addTarget:self action:@selector(tcpFlagsButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        for(int i = 0 ; i < self.tcpFlagsString.count ; i++) {
            NSString *flags = self.tcpFlagsString[i];
            BOOL selected = NO;
            if(indexPath.section == 2) {
                NSNumber *number = [self.tcpFlagsButtonsBoolean valueForKey:flags];
                selected = [number boolValue];
            }
            else if(indexPath.section == 3) {
                NSNumber *number = [self.tcpFlagsSetButtonsBoolean valueForKey:flags];
                selected = [number boolValue];
            }
            
            if([flags isEqualToString:@"FIN"]) {
                cell.finButton.selected = selected;
            }
            else if([flags isEqualToString:@"SYN"]) {
                cell.synButton.selected = selected;
            }
            else if([flags isEqualToString:@"RST"]) {
                cell.rstButton.selected = selected;
            }
            else if([flags isEqualToString:@"PUSH"]) {
                cell.pushButton.selected = selected;
            }
            else if([flags isEqualToString:@"ACK"]) {
                cell.ackButton.selected = selected;
            }
            else if([flags isEqualToString:@"URG"]) {
                cell.urgButton.selected = selected;
            }
            else if([flags isEqualToString:@"ECE"]) {
                cell.eceButton.selected = selected;
            }
            else if([flags isEqualToString:@"CWR"]) {
                cell.cwrButton.selected = selected;
            }
        }
        [cell layoutIfNeeded];
        
        return cell;
    }
    
    return nil;
}

#pragma mark Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return 44.f;
    
    if(self.protocolSegmentedControl.selectedSegmentIndex == 0) {
        if(indexPath.section == 1)
            return 55.f;
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 1) {
        if(indexPath.section == 1)
            return 44.f;
        else if(indexPath.section == 2 || indexPath.section == 3)
            return 60.f;
        else if(indexPath.section == 4)
            return 55.f;
    }
    else if(self.protocolSegmentedControl.selectedSegmentIndex == 2 ||
            self.protocolSegmentedControl.selectedSegmentIndex == 3) {
        if(indexPath.section == 1)
            return 44.f;
        else if(indexPath.section == 2)
            return 55.f;
    }
    
    return 0.f;
}

@end
