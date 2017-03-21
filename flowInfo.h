//
//  flowInfo.h
//  MISP
//
//  Created by iBlock on 14-3-21.
//
//

#import <Foundation/Foundation.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <net/if.h>

typedef NS_ENUM(NSInteger, FlowType) {
    WifiFlow,
    WWanFlow
};

@interface flowInfo : NSObject

- (NSString *)getToDayFlowCount;

- (NSString *)getMonthFlowCount;

- (NSString *)getMonthRemain:(NSString *)flow;

- (NSString *)getDataWithDate:(NSString *)dateStr;

- (double)getMonthRemainNumber:(NSString *)flow;

- (void)removeAllFlowData;

@end
