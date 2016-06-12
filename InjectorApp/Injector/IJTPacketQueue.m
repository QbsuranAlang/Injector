//
//  IJTPacketQueue.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPacketQueue.h"

@interface IJTPacketQueue ()

@property (nonatomic) packet_t *head;
@property (nonatomic) packet_t *tail;

@end

@implementation IJTPacketQueue

- (id)initQueue {
    self = [super init];
    if (self) {
        _head = _tail = NULL;
    }
    return self;
}

- (void)enqueuePacketHeader:(const struct pcap_pkthdr *)header packetContent:(const u_char *)content {
    packet_t *node = (packet_t *)calloc(1, sizeof(*node));
    
    if(!node)
        return;
    
    memcpy(node->content, content, header->caplen);
    memcpy(&node->header, header, sizeof(struct pcap_pkthdr));
    node->next = NULL;
    
    if(_head) //head is not null
        _tail->next = node;
    else //head is null
        _head = node;
    _tail = node;
}

- (BOOL)dequeuePacketHeader:(packet_t *)packet {
    packet_t *temp = _head;
    if(!temp)
        return NO;
    
    memcpy(packet->content, _head->content, _head->header.caplen);
    memcpy(&packet->header, &(_head->header), sizeof(struct pcap_pkthdr));
    
    _head = _head->next;
    if(!_head)
        _tail = NULL;
    
    free(temp);
    return YES;
}

- (void)freeQueue {
    while(_head) {
        packet_t *temp = _head;
        _head = _head->next;
        free(temp);
    }//end while
    _head = _tail = NULL;
}

- (void)dealloc {
    [self freeQueue];
}
@end
