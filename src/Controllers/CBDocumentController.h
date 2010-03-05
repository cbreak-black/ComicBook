//
//  CBDocumentController.h
//  ComicBook
//
//  Created by cbreak on 05.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBDocumentController : NSDocumentController
{

}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions;

@end
