//
//  BleCustomViewController.m
//  BluetoothTool
//
//  Created by shilu lai on 2019/5/27.
//  Copyright © 2019 shilu lai. All rights reserved.
//

#import "BleCustomViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BleCustomViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITextView *logview;
@property (weak, nonatomic) IBOutlet UITableView *table;

@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (nonatomic,strong ) NSMutableArray <CBPeripheral*>*devices;// 扫描到的外围设备

@property (nonatomic,strong ) CBCentralManager *manager;// 中心设备


@property (nonatomic, strong)CBCharacteristic *characteristic;
@property (nonatomic, strong)CBCharacteristic *notifiCharacteristic;
@property (nonatomic, strong)CBCharacteristic *readwritenotifiCharacteristic;
@property (nonatomic, strong)CBCharacteristic *readCharacteristic;
@property (nonatomic,strong)CBPeripheral *Peripheral;




@end

static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const readwriteCharacteristicUUID =  @"FFF2";
static NSString *const ServiceUUID2 =  @"FFE0";
static NSString *const readCharacteristicUUID =  @"FFE1";

@implementation BleCustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.devices =[NSMutableArray array];
     self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.table.delegate = self;
    self.table.dataSource = self;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

-(void) startScan{
    NSLog(@"scan....");
    
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    
    //[self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    //3秒后停止。(开启扫描后会不停的扫描)
    [self performSelector:@selector(stopScan) withObject:nil afterDelay:10];
}

/**
 *  停止扫描
 */
-(void)stopScan{
    [self.manager stopScan];
    NSLog(@"stopScan....");
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBManagerStatePoweredOn:
            NSLog(@"蓝牙已打开");
            //自动开始扫描
            [self startScan];
            
            break;
        case CBManagerStateUnknown:
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"蓝牙未打开");
            
            break;
        case CBManagerStateResetting:
            //            [self showInfo:@"蓝牙初始化中"];
            break;
        case CBManagerStateUnsupported:
            NSLog(@"蓝牙不支持状态");
            
            //            [self showInfo:@"蓝牙不支持状态"];
            break;
        case CBManagerStateUnauthorized:
            //            [self showInfo:@"蓝牙设备未授权"];
            break;
        default:
            break;
    }
}
-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                 RSSI:(NSNumber *)RSSI{
    if (peripheral.name) {
        [self.devices addObject:peripheral];
    }
        [self.table reloadData];
        NSLog(@"发现外围设备:%@---RSSI:%@---advertisementData:%@",peripheral,RSSI,advertisementData);
 
}
/**
 *  蓝牙连接成功时候的代理
 *
 *  @param central    中心设备
 *  @param peripheral 当前连接的设备
 */
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"%@名字的蓝牙连接成功",peripheral.name);
   
    self.Peripheral = peripheral;
    CBUUID *ServiceUUIDa = [CBUUID UUIDWithString:ServiceUUID1];
      CBUUID *ServiceUUIDb = [CBUUID UUIDWithString:ServiceUUID2];
    [peripheral discoverServices:@[ServiceUUIDa,ServiceUUIDb]];
    peripheral.delegate =self;
    [self addlogs:[NSString stringWithFormat:@"[%@]连接成功",peripheral.name]];

    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        //[self getAllCharacteristicsFromKeyfob:peripheral];
        
        // 发现指定服务的指定特征
        if (peripheral.services.count !=0) {
            for (CBService *service in peripheral.services) {
                    [self addlogs:[NSString stringWithFormat:@" 发现服务：[%@]",service.UUID]];
                    [peripheral discoverCharacteristics:nil forService:service];
            }
        }else{
            //sb
            NSLog(@"失败");
        }
        
    }
    else {
        NSLog(@"失败");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        if (service.characteristics.count!=0) {
            
            
            // 发现指定服务的指定特征
            for (CBCharacteristic *characteristic in service.characteristics) {
                
                    [self addlogs:[NSString stringWithFormat:@" 发现特征：[%@] 属于服务：[%@]",characteristic.UUID,service.UUID]];
                // 发现了可写的特征
                if ([characteristic.UUID.UUIDString isEqualToString:notiyCharacteristicUUID]) {
                    
                    
                    self.notifiCharacteristic = characteristic;
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    
                    
                }
                if ([characteristic.UUID.UUIDString isEqualToString:readwriteCharacteristicUUID]) {
                    
                    self.readwritenotifiCharacteristic= characteristic;
                    
                }
                if ([characteristic.UUID.UUIDString isEqualToString:readCharacteristicUUID]) {
                    
                    self.readCharacteristic= characteristic;
                    
                    //
                    
                }
                
            }
            
        }else{
            NSLog(@"失败");
        }
    }
    else {
        NSLog(@"失败");
    }
}

/**
 *  蓝牙链接失败的代理
 *
 *  @param central    中心设备
 *  @param peripheral 当前连接的外设
 *  @param error      错误信息
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;{
    NSLog(@"%@名字的蓝牙连接失败",peripheral.name);
       [self addlogs:[NSString stringWithFormat:@"[%@]连接失败",peripheral.name]];
}
/**
 *  蓝牙断开连接的代理
 *
 *  @param central    中心设备
 *  @param peripheral 当前需要断开连接的外设
 *  @param error      错误信息
 */
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@名字的蓝牙断开链接",peripheral.name);
   [self addlogs:[NSString stringWithFormat:@"[%@]断开链接",peripheral.name]];
    

}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
    }else{
        NSString * str  =[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"%@",str);
       [self addlogs:[NSString stringWithFormat:@"收到设备中心【%@】的数据：%@",characteristic.UUID,str]];
    }
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devices.count;
    
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell1 = [tableView
                              dequeueReusableCellWithIdentifier:@"cell"];
    if (cell1==nil) {
        cell1 =[ [UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    //cell1.txtDeviceAddre.text=self.devices[indexPath.row].identifier;
    NSString *c = [NSString stringWithFormat:@"%@",self.devices[indexPath.row].name];
    cell1.textLabel.text = c;
    
    return cell1;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CBPeripheral *peripheral=  self.devices[indexPath.row];
    [self.manager connectPeripheral:peripheral options:nil];
}



-(void)addlogs:(NSString *)string
{
    
    if ([self.logview.text isEqualToString:@""]) {
        self.logview.text = [@"" stringByAppendingString:[NSString stringWithFormat:@"%@:%@\n\n",[self getdata],string]];
    }else{
        self.logview.text = [self.logview.text stringByAppendingString:[NSString stringWithFormat:@"%@:%@\n\n",[self getdata],string]];
    }
    [self.logview scrollRangeToVisible:NSMakeRange(self.logview.text.length, 1)];
}

-(NSString *)getdata
{
    　NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    
    //现在时间,你可以输出来看下是什么格式
    
    NSDate *datenow = [NSDate date];
    
    //----------将nsdate按formatter格式转成nsstring
    
    NSString *nowtimeStr = [formatter stringFromDate:datenow];
    
    return nowtimeStr;
}

- (IBAction)write:(id)sender {
    [self.textfield resignFirstResponder];
    self.editing = NO;
    if (![self.textfield.text isEqualToString:@""]) {
          [self.Peripheral writeValue:[self.textfield.text dataUsingEncoding:NSUTF8StringEncoding]forCharacteristic:self.readwritenotifiCharacteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"请输入字符串");
    }

}
- (IBAction)read:(id)sender {
       [self.Peripheral readValueForCharacteristic:self.readCharacteristic];
}


@end
