//
//  STAAppDelegate.h
//  StaticTextAccessibility
//

#import <Cocoa/Cocoa.h>

@interface STAAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly) NSAttributedString *labelValue;

@end
