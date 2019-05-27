//
//  bleServerViewController.m
//  BluetoothTool
//
//  Created by shilu lai on 2019/5/27.
//  Copyright © 2019 shilu lai. All rights reserved.
//

#import "bleServerViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const readwriteCharacteristicUUID =  @"FFF2";
static NSString *const ServiceUUID2 =  @"FFE0";
static NSString *const readCharacteristicUUID =  @"FFE1";
static NSString *const LocalNameKey =  @"holographic";


@interface bleServerViewController ()<CBPeripheralManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *logview;

@property(nonatomic,strong)CBPeripheralManager *peripheralManager;

@property(nonatomic,strong)NSTimer *timer;

@end

@implementation bleServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.logview.layoutManager.allowsNonContiguousLayout = NO;
      self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}
- (void)setUp
{
    
  
    // characteristic字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions: CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    /*
     可读写的characteristics
     properties：CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable | CBAttributePermissionsWriteable
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    //设置descriptor
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    
    
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    
    /*
     只读的Characteristic
     properties：CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    
    //添加后就会调用代理的- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
    [self.peripheralManager addService:service1];
    [self.peripheralManager addService:service2];
    [self addlogs:@"蓝牙开启成功"];
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
            //在这里判断蓝牙设别的状态  当开启了则可调用  setUp方法(自定义)
        case CBManagerStatePoweredOn:
            NSLog(@"powered on");
            // 运行初始化方法
            [self setUp];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"powered off");
            break;
            
        default:
            break;
    }
}
// 添加了服务，添加服务后需要广播，一旦广播，外围设备就可以被中心设备发现，同样外围设备所携带的数据也能被中心设备捕获
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",[error localizedDescription]);
        return;
    }
    // 添加服务后，发送广播
    // 发送广播后会自动调用
    // - (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
    [self.peripheralManager startAdvertising:@{
                                          CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ServiceUUID1],[CBUUID UUIDWithString:ServiceUUID2]],
                                          CBAdvertisementDataLocalNameKey : LocalNameKey
                                          }];

    [self addlogs:[NSString stringWithFormat:@"添加服务【%@】成功",service.UUID]];
}

// 通知发送了广播
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    [self addlogs:@"已经开始广播"];
    NSLog(@"已经开始广播");
}

// 中心设备订阅特征后会调用这个方法
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    //发送数据
     CBMutableCharacteristic *t = (CBMutableCharacteristic *)characteristic;
    [self.peripheralManager updateValue:[@"欢迎订阅服务" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:t onSubscribedCentrals:nil];
    [self addlogs:[NSString stringWithFormat:@"【%@】订阅了服务",characteristic.UUID]];
           [self addlogs:[NSString stringWithFormat:@"【%@】发给中心设备一条数据:%@",t .UUID,@"欢迎订阅服务"]];
}

// 中心设备读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        
          [self addlogs:[NSString stringWithFormat:@"【%@】收到中心设备发送一条读数据的请求",request.characteristic.UUID]];
        //        NSData *data = request.characteristic.value;
        NSData *datas = [[NSString stringWithFormat:@"你请求了一条数据"] dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:datas];
        //对请求作出成功响应
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        
        [self addlogs:[NSString stringWithFormat:@"【%@】发给中心设备一条数据:%@",request.characteristic.UUID,[[NSString alloc] initWithBytes:datas.bytes length:datas.length encoding:NSUTF8StringEncoding]]];
        
    }else{
           [self addlogs:[NSString stringWithFormat:@"【%@】没有权限数数据",request.characteristic.UUID]];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


// 外围设备写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        
        [self addlogs:[NSString stringWithFormat:@"【%@】收到中心设备发送一条读数据的请求",request.characteristic.UUID]];
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        NSLog(@"收到中心设备发送信息:%@",[[NSString alloc] initWithData:c.value encoding:NSUTF8StringEncoding]);
        
        [self addlogs:[NSString stringWithFormat:@"【%@】收到中心设备发送信息:%@",request.characteristic.UUID,[[NSString alloc] initWithData:c.value encoding:NSUTF8StringEncoding]]];
        
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
           [self addlogs:[NSString stringWithFormat:@"【%@】发给中心设备一条数据:%@",request.characteristic.UUID,[[NSString alloc] initWithBytes:request.value.bytes length:request.value.length encoding:NSUTF8StringEncoding]]];
        
    }else{
         [self addlogs:[NSString stringWithFormat:@"【%@】没有权限写数据",request.characteristic.UUID]];
        [self.peripheralManager  respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

// 外围设备更新描述后调用
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
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
@end
