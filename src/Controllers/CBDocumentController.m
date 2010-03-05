//
//  CBDocumentController.m
//  ComicBook
//
//  Created by cbreak on 05.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDocumentController.h"


@implementation CBDocumentController

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setCanChooseDirectories:YES];
	return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
