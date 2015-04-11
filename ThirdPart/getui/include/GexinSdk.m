//
//  GexinSdk.m
//  Demo
//
//  Created by Quant on 14-8-29.
//  Copyright (c) 2014年 Quant. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GexinSdk.h"

@implementation GexinSdk

-(NSString*)sayHello:(NSString*)greeting withName: (NSString*)name
{
    NSString *string = [NSString stringWithFormat:@"Hi,%@ %@.", name, greeting];
    return string;
}
@end