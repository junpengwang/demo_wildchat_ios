//
//  ViewController.m
//  WildChat
//
//  Created by Garin on 15/7/22.
//  Copyright (c) 2015年 Wilddog. All rights reserved.
//

#import "ViewController.h"

#define kWilddogUrl @"https://demochat.wilddogio.com/msg"

@interface ViewController ()
@property (nonatomic,assign) BOOL newMessagesOnTop;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.chat = [[NSMutableArray alloc] init];
    
    _wilddog = [[Wilddog alloc] initWithUrl:kWilddogUrl];
    
    
    self.name = [NSString stringWithFormat:@"Guest%d", arc4random() % 1000];
    [_nameField setTitle:self.name forState:UIControlStateNormal];
    
    _newMessagesOnTop = YES;
    
    __block BOOL initialAdds = YES;
    
    [self.wilddog observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot *snapshot) {
        
        if (_newMessagesOnTop) {
            if (snapshot.value) {
                [self.chat insertObject:snapshot.value atIndex:0];
            }
        }else{
            [self.chat addObject:snapshot.value];
        }
        
        if (!initialAdds) {
            [self.tableView reloadData];
        }
        
    }];
    
    [self.wilddog observeSingleEventOfType:WEventTypeValue withBlock:^(WDataSnapshot *snapshot) {
        
        [self.tableView reloadData];
        initialAdds = NO;
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Text field handling

// This method is called when the user enters text in the text field.
// We add the chat message to our Firebase.
- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    
    // This will also add the message to our local array self.chat because
    // the FEventTypeChildAdded event will be immediately fired.
    [[self.wilddog childByAutoId] setValue: aTextField.text];
    
    [aTextField setText:@""];
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section
{
    return [self.chat count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id chatMessage = [self.chat objectAtIndex:indexPath.row];

    if (![chatMessage isKindOfClass:[NSString class]]) {
        return 0;
    }
    NSString *text = chatMessage;
    
    // typical textLabel.frame = {{10, 30}, {260, 22}}
    const CGFloat TEXT_LABEL_WIDTH = 260;
    CGSize constraint = CGSizeMake(TEXT_LABEL_WIDTH, 20000);
    
    // typical textLabel.font = font-family: "Helvetica"; font-weight: bold; font-style: normal; font-size: 18px
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping]; // requires iOS 6+
    const CGFloat CELL_CONTENT_MARGIN = 22;
    CGFloat height = MAX(CELL_CONTENT_MARGIN + size.height, 44);
    
    return height;
}

- (UITableViewCell*)tableView:(UITableView*)table cellForRowAtIndexPath:(NSIndexPath *)index
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.textLabel.numberOfLines = 0;
    }
    
    id chatMessage = [self.chat objectAtIndex:index.row];
    
    if (![chatMessage isKindOfClass:[NSDictionary class]]) {
        cell.textLabel.text = chatMessage;
        return cell;
    }
    cell.textLabel.text = chatMessage[@"text"];
    
    return cell;
}

#pragma mark - Keyboard handling

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:NO];
}

- (void)moveView:(NSDictionary*)userInfo up:(BOOL)up
{
    CGRect keyboardEndFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]
     getValue:&keyboardEndFrame];
    
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]
     getValue:&animationCurve];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey]
     getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    int y = keyboardFrame.size.height * (up ? -1 : 1);
    self.view.frame = CGRectOffset(self.view.frame, 0, y);
    
    [UIView commitAnimations];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([_textField isFirstResponder]) {
        [_textField resignFirstResponder];
    }
}

@end
