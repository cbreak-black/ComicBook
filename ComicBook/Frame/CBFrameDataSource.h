//
//  CBFrameDataSource.h
//  ComicBook
//
//  Created by cbreak on 2013.03.15.
//  Copyright (c) 2013 the-color-black.net. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 \brief Data source interface for Frame Data Sources
 */
@protocol CBFrameDataSource <NSObject>
@property (readonly) NSData * frameData;
@property (readonly) NSString * framePath;
@end

/*!
 \brief Helper implementation of the CBFrameDataSource interface for stored data
 */
@interface CBFrameStoredDataSource : NSObject<CBFrameDataSource>
{
	NSData * frameData;
	NSString * framePath;
}

- (id)initWithData:(NSData*)data withPath:(NSString*)path;

@property (readonly) NSData * frameData;
@property (readonly) NSString * framePath;

@end
