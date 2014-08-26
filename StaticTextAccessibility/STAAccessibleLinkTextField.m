//
//  STAAccessibleLinkTextField.m
//  StaticTextAccessibility
//

#import "STAAccessibleLinkTextField.h"

@interface LinkProxyObject : NSObject

@property (copy) NSString *title;
@property (copy) NSURL *url;
@property (retain) id parent;
@property (retain) id window;
@property (retain) id topLevelUIElement;

@end

@implementation LinkProxyObject

- (void)dealloc
{
	NSAccessibilityPostNotification(self, NSAccessibilityUIElementDestroyedNotification);
}

- (BOOL)accessibilityIsIgnored
{
	return NO;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
    return NO;
}

- (NSArray *)accessibilityAttributeNames
{
	NSArray *newAttributes = @[NSAccessibilityRoleAttribute,
							   NSAccessibilitySubroleAttribute,
							   NSAccessibilityRoleDescriptionAttribute,
							   NSAccessibilityTitleAttribute,
							   NSAccessibilityURLAttribute,
							   NSAccessibilityParentAttribute,
							   NSAccessibilityWindowAttribute,
							   NSAccessibilityTopLevelUIElementAttribute,
							   ];
	
	return newAttributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
	{
		return NSAccessibilityLinkRole;
	}
	else if ([attribute isEqualToString:NSAccessibilitySubroleAttribute])
	{
		return NSAccessibilityTextLinkSubrole;
	}
	else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
	{
		return NSAccessibilityRoleDescription(NSAccessibilityLinkRole, NSAccessibilityTextLinkSubrole);
	}
	else if ([attribute isEqualToString:NSAccessibilityTitleAttribute])
	{
		return self.title;
	}
	else if ([attribute isEqualToString:NSAccessibilityURLAttribute])
	{
		return self.url;
	}
	else if ([attribute isEqualToString:NSAccessibilityParentAttribute])
	{
		return self.parent;
	}
	else if ([attribute isEqualToString:NSAccessibilityWindowAttribute])
	{
		return self.window;
	}
	else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute])
	{
		return self.topLevelUIElement;
	}
	
	return nil;
}


- (NSArray *)accessibilityActionNames
{
	return @[NSAccessibilityPressAction];
}


- (NSString *)accessibilityActionDescription:(NSString *)action
{
	if ([action isEqualToString:NSAccessibilityPressAction]) {
		return NSAccessibilityActionDescription(NSAccessibilityPressAction);
	}
	
	return @"";
}


- (void)accessibilityPerformAction:(NSString *)action
{
	if ([action isEqualToString:NSAccessibilityPressAction]) {
		[[NSWorkspace sharedWorkspace] openURL:self.url];
	}
}

- (BOOL)accessibilityNotifiesWhenDestroyed
{
	return YES;
}

@end



#pragma mark -

@implementation STAAccessibleLinkTextField

+ (Class)cellClass
{
    return [STAAccessibleLinkTextFieldCell class];
}


@end


#pragma mark -

@implementation STAAccessibleLinkTextFieldCell

@synthesize linkProxies;

- (id)copyWithZone:(NSZone *)zone
{
    STAAccessibleLinkTextFieldCell *copy;
    
    if ((copy = [super copyWithZone:zone]))
    {
        copy->linkProxies = [linkProxies copy];
    }
    
    return copy;
}


#pragma mark Overrides

- (void)setAttributedStringValue:(NSAttributedString *)obj
{
	self.linkProxies = nil; // Reset the proxy objects since the string value has changed
	
	[super setAttributedStringValue:obj];
}


#pragma mark Accessibility

- (NSDictionary *)linkProxies
{
	if (linkProxies == nil) {
		NSMutableDictionary *proxies = [NSMutableDictionary dictionary];
		
		[self.attributedStringValue enumerateAttribute:NSLinkAttributeName
											   inRange:NSMakeRange(0, self.stringValue.length)
											   options:0
											usingBlock:^(id value, NSRange range, BOOL *stop) {
												if (value != nil)
												{
													LinkProxyObject *proxy = [[LinkProxyObject alloc] init];
													proxy.url = value;
													proxy.title = [self.stringValue substringWithRange:range];
													proxy.window = [super accessibilityAttributeValue:NSAccessibilityWindowAttribute];
													proxy.topLevelUIElement = [super accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
													proxy.parent = self;
													
													[proxies setObject:proxy forKey:[NSValue valueWithRange:range]];
												}
											}];
		linkProxies = [NSDictionary dictionaryWithDictionary:proxies];
	}
	
	return linkProxies;
}

- (BOOL)accessibilityIsIgnored
{
	return NO;
}


- (NSArray *)accessibilityAttributeNames
{
	return [[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityChildrenAttribute];
}


- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute])
	{
		if (self.linkProxies.count > 0) {
			return [self.linkProxies allValues];
		}
	}
	
	
    return [super accessibilityAttributeValue:attribute];
}


- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter
{
	if ([attribute isEqualToString:NSAccessibilityAttributedStringForRangeParameterizedAttribute])
	{
//		NSLog(@"att string for range: %@", parameter);
		NSMutableAttributedString *outAttString = [super accessibilityAttributeValue:attribute forParameter:parameter];
		NSAttributedString *selfAttString = [self attributedStringValue];
		
		[selfAttString enumerateAttribute:NSLinkAttributeName
								  inRange:[parameter rangeValue]
								  options:0
							   usingBlock:^(id value, NSRange linkRange, BOOL *stop) {
								   if (value != nil)
								   {
									   for (NSValue *rangeValue in self.linkProxies)
									   {
										   NSRange linkRangeInParam = NSIntersectionRange(linkRange, [rangeValue rangeValue]);
										   
										   if (linkRangeInParam.length > 0)
										   {
											   // Scenario:
											   // This is your string: "Word word LINK word."
											   // Passed-in range param is (5,9)
											   // The block finds LINK with range (10,4) in the full string
											   //
											   // But the range param starts at 5! So we must remove leading chars from the range.
											   linkRangeInParam.location -= [parameter rangeValue].location;
											   id proxyObject = [self.linkProxies objectForKey:rangeValue];
											   
											   if (proxyObject)
											   {
												   [outAttString addAttribute:NSAccessibilityLinkTextAttribute value:proxyObject range:linkRangeInParam];
											   }
										   }
									   }
								   }
							   }];
		
//		NSLog(@"out string: %@", outAttString);
		// returning NSAttributedString instead of NSMutableAttributedString is required
		// for the links (and perhaps other stuff) to work (mostly).
		// See: http://lists.apple.com/archives/accessibility-dev/2014/Aug/msg00021.html
		return [[NSAttributedString alloc] initWithAttributedString:outAttString];
	}
//	else if ([attribute isEqualToString:NSAccessibilityRTFForRangeParameterizedAttribute])
//	{
//		id rtf = [super accessibilityAttributeValue:attribute forParameter:parameter];
//		NSLog(@"out rtf: %@", rtf);
//	}
	
	return [super accessibilityAttributeValue:attribute forParameter:parameter];
}

@end
