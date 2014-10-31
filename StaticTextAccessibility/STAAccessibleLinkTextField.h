//
//  STAAccessibleLinkTextField.h
//  StaticTextAccessibility
//

#import <Foundation/Foundation.h>

@interface STAAccessibleLinkTextField : NSTextField <NSTextViewDelegate>

@end

@interface STAAccessibleLinkTextFieldCell : NSTextFieldCell
{
	NSDictionary *_linkProxies;
}

@property (nonatomic) NSDictionary *linkProxies;

@end
