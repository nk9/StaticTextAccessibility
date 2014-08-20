//
//  STAAccessibleLinkTextField.h
//  StaticTextAccessibility
//

#import <Foundation/Foundation.h>
#import "STAAccessibleLinkFieldEditor.h"

@interface STAAccessibleLinkTextField : NSTextField <NSTextViewDelegate>
{
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;
	NSTextStorage *textStorage;
}
@end

@interface STAAccessibleLinkTextFieldCell : NSTextFieldCell
{
	NSDictionary *linkProxies;
}

@property (nonatomic) NSDictionary *linkProxies;

@end
