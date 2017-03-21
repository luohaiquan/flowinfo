//
//  flowInfo.m
//  MISP
//
//  Created by iBlock on 14-3-21.
//
//

#import "flowInfo.h"
#import "tbFlowInfo.h"

@implementation flowInfo
{
    NSString* sql;
}

-(NSString *)bytesToAvaiUnit:(int)bytes
{
	if(bytes < 1024)		// B
	{
		return [NSString stringWithFormat:@"%dB", bytes];
	}
	else if(bytes >= 1024 && bytes < 1024 * 1024)	// KB
	{
		return [NSString stringWithFormat:@"%.1fKB", (double)bytes / 1024];
	}
	else if(bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024)	// MB
	{
		return [NSString stringWithFormat:@"%.2fMB", (double)bytes / (1024 * 1024)];
	}
	else	// GB
	{
		return [NSString stringWithFormat:@"%.3fGB", (double)bytes / (1024 * 1024 * 1024)];
	}
}

-(uint32_t)checkNetworkflow:(FlowType)type
{
    struct ifaddrs *ifa_list = 0, *ifa;
    
    if (getifaddrs(&ifa_list) == -1)
        
    {
        
        return -1;
    }
    
    uint32_t iBytes     = 0;
    
    uint32_t oBytes     = 0;
    
    uint32_t allFlow    = 0;
    
    uint32_t wifiIBytes = 0;
    
    uint32_t wifiOBytes = 0;
    
    uint32_t wifiFlow   = 0;
    
    uint32_t wwanIBytes = 0;
    
    uint32_t wwanOBytes = 0;
    
    uint32_t wwanFlow   = 0;
    
    struct timeval time ;
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
        
    {
        
        if (AF_LINK != ifa->ifa_addr->sa_family)
            
            continue;
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            
            continue;
        
        if (ifa->ifa_data == 0)
            
            continue;
        // Not a loopback device.
        
        // network flow
        
        if (strncmp(ifa->ifa_name, "lo", 2))
            
        {
            
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            iBytes += if_data->ifi_ibytes;
            
            oBytes += if_data->ifi_obytes;
            
            allFlow = iBytes + oBytes;
            
            time = if_data->ifi_lastchange;
            
            // NSLog(@"1111===%s :iBytes is %d, oBytes is %d", ifa->ifa_name, iBytes, oBytes);
            
        }
        
        //<span style="font-family: Tahoma, Helvetica, Arial, 宋体, sans-serif; ">WIFI流量统计功能</span>
        
        if (!strcmp(ifa->ifa_name, "en0"))
            
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            wifiIBytes += if_data->ifi_ibytes;
            
            wifiOBytes += if_data->ifi_obytes;
            
            wifiFlow    = wifiIBytes + wifiOBytes;
            
        }
        
        //<span style="font-family: Tahoma, Helvetica, Arial, 宋体, sans-serif; ">3G和GPRS流量统计</span>
        
        if (!strcmp(ifa->ifa_name, "pdp_ip0"))
            
        {
            
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            wwanIBytes += if_data->ifi_ibytes;
            
            wwanOBytes += if_data->ifi_obytes;
            
            wwanFlow    = wwanIBytes + wwanOBytes;
            
            //NSLog(@"111122===%s :iBytes is %d, oBytes is %d",  ifa->ifa_name, iBytes, oBytes);
            
        }
        
    }
    
    freeifaddrs(ifa_list);
    
    switch (type)
    {
        case WifiFlow:
        {
            return wifiFlow;
        }
            break;
            
        case WWanFlow:
        {
            return wwanFlow;
        }
            break;
    }
    
    /*
     NSString *changeTime=[NSString stringWithFormat:@"%s",ctime(&time)];
     
     NSLog(@"changeTime==%@",changeTime);
     NSString *receivedBytes= [self bytesToAvaiUnit:iBytes];
     
     NSLog(@"receivedBytes==%@",receivedBytes);
     NSString *sentBytes       = [self bytesToAvaiUnit:oBytes];
     
     NSLog(@"sentBytes==%@",sentBytes);
     NSString *networkFlow      = [self bytesToAvaiUnit:allFlow];
     
     NSLog(@"networkFlow==%@",networkFlow);
     
     NSString *wifiReceived   = [self bytesToAvaiUnit:wifiIBytes];
     
     NSLog(@"wifiReceived==%@",wifiReceived);
     NSString *wifiSent       = [self bytesToAvaiUnit: wifiOBytes];
     
     NSLog(@"wifiSent==%@",wifiSent);
     
     NSString *wifiBytes      = [self bytesToAvaiUnit:wifiFlow];
     
     NSLog(@"wifiBytes==%@",wifiBytes);
     NSString *wwanReceived   = [self bytesToAvaiUnit:wwanIBytes];
     
     NSLog(@"wwanReceived==%@",wwanReceived);
     NSString *wwanSent       = [self bytesToAvaiUnit:wwanOBytes];
     
     NSLog(@"wwanSent==%@",wwanSent);
     NSString *wwanBytes      = [self bytesToAvaiUnit:wwanFlow];
     
     NSLog(@"wwanBytes==%@",wwanBytes);
     */
}

- (void)flowCount
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [NSDate date];
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
    sql = [NSString stringWithFormat:@"WHERE flow_date = '%@'",dateStr];

    tbFlowInfo *flowInfo = (tbFlowInfo *)[tbFlowInfo findFirstByCriteria:sql];

    if (flowInfo != nil)
    {
        uint32_t currentFlow = [self checkNetworkflow:WWanFlow];
        flowInfo.wwanFlow = currentFlow - flowInfo.systemWwanFlow + flowInfo.wwanFlow;
        flowInfo.systemWwanFlow = currentFlow;
        [flowInfo save];
        [tbFlowInfo clearCache];
    }
    else
    {
        tbFlowInfo *newFlowInfo = [[tbFlowInfo alloc] init];
        newFlowInfo.flowDate = dateStr;
        newFlowInfo.systemWwanFlow = [self checkNetworkflow:WWanFlow];
        newFlowInfo.wwanFlow = 0;
        [newFlowInfo save];
        [tbFlowInfo clearCache];
        [newFlowInfo release];
        newFlowInfo = nil;
    }
}

- (NSString *)getToDayFlowCount
{
    [self flowCount];
    
    tbFlowInfo *flowInfo = (tbFlowInfo *)[tbFlowInfo findFirstByCriteria:sql];
    return [self bytesToAvaiUnit:flowInfo.wwanFlow];
}

- (NSString *)getDataWithDate:(NSString *)dateStr
{
    NSString *selectSQL = [NSString stringWithFormat:@"WHERE flow_date = '%@'",dateStr];

    tbFlowInfo *flowInfo = (tbFlowInfo *)[tbFlowInfo findFirstByCriteria:selectSQL];
    
    if (flowInfo == nil) {
        return [self bytesToAvaiUnit:0];
    }
    
    uint32_t flow = flowInfo.wwanFlow;

    return [self bytesToAvaiUnit:flow];
}

- (void)removeAllFlowData
{
    NSArray *allFlowObje = [tbFlowInfo allObjects];
    
    for (tbFlowInfo *flowInfo in allFlowObje)
    {
        [flowInfo deleteObject];
    }
    
    [tbFlowInfo clearCache];
}

- (NSString *)getMonthFlowCount
{
    [self flowCount];
    
    uint32_t allFlow = [self monthFlowCount];
    return [self bytesToAvaiUnit:allFlow];
}

- (uint32_t)monthFlowCount
{
    uint32_t allFlow = 0;
    NSArray *flowArray = [tbFlowInfo allObjects];
    
    for (tbFlowInfo *flow in flowArray)
    {
        allFlow += flow.wwanFlow;
    }
    
    return allFlow;
}

- (NSString *)getMonthRemain:(NSString *)flow
{
    double allFlow = [flow doubleValue] * 1024 * 1024;
    double currentFlow = [self monthFlowCount];
    
    double remainFlow = allFlow - currentFlow;
    
    return [self bytesToAvaiUnit:remainFlow];
}

- (double)getMonthRemainNumber:(NSString *)flow
{
    double allFlow = [flow doubleValue] * 1024 * 1024;
    double currentFlow = [self monthFlowCount];
    
    double value = (currentFlow / allFlow) * 100;
    return value;
}

@end






















