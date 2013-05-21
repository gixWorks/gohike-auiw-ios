//
//  Route.h
//
//  Created by Giovanni Maggini on 5/16/13
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Route : NSObject <NSCoding>

@property (nonatomic, assign) double profileid;
@property (nonatomic, strong) NSString *picture;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *internalBaseClassDescription;

+ (Route *)modelObjectWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
