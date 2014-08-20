//
//  STAAccessibleTextView.m
//  StaticTextAccessibility
//

#import "STAAccessibleTextView.h"

@implementation STAAccessibleTextView

- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter
{
	if ([attribute isEqualToString:NSAccessibilityAttributedStringForRangeParameterizedAttribute])
	{
//		NSLog(@"parameterized att string: %@", [super accessibilityAttributeValue:attribute forParameter:parameter]);
	}

	return [super accessibilityAttributeValue:attribute forParameter:parameter];
}

@end
