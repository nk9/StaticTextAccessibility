//
//  STAAppDelegate.m
//  StaticTextAccessibility
//

#import "STAAppDelegate.h"

@implementation STAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (NSAttributedString *)labelValue
{
	NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:@"Looks like you'll never be a concert flautist."];
	[attStr setAttributes:@{NSLinkAttributeName:[NSURL URLWithString:@"http://en.wikipedia.org"],
							NSForegroundColorAttributeName:[NSColor blueColor]} range:NSMakeRange(0, 5)];
	[attStr setAttributes:@{NSLinkAttributeName:[NSURL URLWithString:@"http://cuteoverload.com"],
							NSForegroundColorAttributeName:[NSColor blueColor]} range:NSMakeRange(11, 12)];
	[attStr setAttributes:@{NSLinkAttributeName:[NSURL URLWithString:@"http://dailyotter.org"],
							NSForegroundColorAttributeName:[NSColor blueColor]} range:NSMakeRange(37, 8)];
	
	return attStr;
}

@end
