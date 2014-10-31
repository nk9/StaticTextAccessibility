//
//  STAAccessibleLinkTextField.m
//  StaticTextAccessibility
//

#import "STAAccessibleLinkTextField.h"


@interface LinkProxy : NSObject

@property (copy) NSString *title;
@property (copy) NSURL *url;

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

- (id)copyWithZone:(NSZone *)zone
{
	STAAccessibleLinkTextFieldCell *copy;
	
	if ((copy = [super copyWithZone:zone]))
	{
		copy->_linkProxies = [_linkProxies copy];
	}
	
	return copy;
}


#pragma mark Overrides

- (void)resetProxies
{
	self.linkProxies = nil;
}


- (void)setStringValue:(NSString *)obj
{
	[self resetProxies];
	[super setStringValue:obj];
}


- (void)setAttributedStringValue:(NSAttributedString *)obj
{
	[self resetProxies];
	[super setAttributedStringValue:obj];
}


- (void)setObjectValue:(id)obj
{
	[self resetProxies];
	[super setObjectValue:obj];
}


#pragma mark Accessors

- (NSDictionary *)linkProxies
{
	if (_linkProxies == nil)
	{
		NSMutableDictionary *proxies = [NSMutableDictionary dictionary];
		
		[self.attributedStringValue enumerateAttribute:NSLinkAttributeName
											   inRange:NSMakeRange(0, self.stringValue.length)
											   options:0
											usingBlock:^(id value, NSRange range, BOOL *stop) {
												if (value != nil)
												{
													LinkProxy *proxy = [[LinkProxy alloc] init];
													proxy.url = value;
													proxy.title = [self.stringValue substringWithRange:range];
													
													[proxies setObject:proxy forKey:[NSValue valueWithRange:range]];
												}
											}];
		self.linkProxies = [NSDictionary dictionaryWithDictionary:proxies];
	}
	
	return _linkProxies;
}


#pragma mark Accessibility

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
		if (self.linkProxies.count > 0)
		{
			return [self.linkProxies allValues];
		}
	}
	
	return [super accessibilityAttributeValue:attribute];
}


- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter
{
	if ([attribute isEqualToString:NSAccessibilityAttributedStringForRangeParameterizedAttribute])
	{
		NSMutableAttributedString *outAttString = [super accessibilityAttributeValue:attribute forParameter:parameter];
		NSAttributedString *selfAttString = [self attributedStringValue];
		
		// Must use the full string, not the substring, because proxies are stored by their range value
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
		
		// Must return an immutable string.
		// See: http://lists.apple.com/archives/accessibility-dev/2014/Aug/msg00021.html
		return [[NSAttributedString alloc] initWithAttributedString:outAttString];
	}
	//
	// Not implemented right now because Apple doesn't use it.
	// See: http://lists.apple.com/archives/accessibility-dev/2014/Aug/msg00015.html
	//
	//	else if ([attribute isEqualToString:NSAccessibilityRTFForRangeParameterizedAttribute])
	//	{
	//		id rtf = [super accessibilityAttributeValue:attribute forParameter:parameter];
	//		NSLog(@"out rtf: %@", rtf);
	//	}
	
	return [super accessibilityAttributeValue:attribute forParameter:parameter];
}

@end


#pragma mark -

@implementation LinkProxy

- (void)dealloc
{
	NSAccessibilityPostNotification(self, NSAccessibilityUIElementDestroyedNotification);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<LinkProxy %p: '%@'->'%@'>", self, self.title, self.url];
}


#pragma mark Accessibility


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
	
	return nil;
}


- (NSArray *)accessibilityActionNames
{
	return @[NSAccessibilityPressAction];
}


- (NSString *)accessibilityActionDescription:(NSString *)action
{
	if ([action isEqualToString:NSAccessibilityPressAction])
	{
		return NSAccessibilityActionDescription(NSAccessibilityPressAction);
	}
	
	return @"";
}


- (void)accessibilityPerformAction:(NSString *)action
{
	if ([action isEqualToString:NSAccessibilityPressAction])
	{
		[[NSWorkspace sharedWorkspace] openURL:self.url];
	}
}


- (BOOL)accessibilityNotifiesWhenDestroyed
{
	return YES;
}

@end
