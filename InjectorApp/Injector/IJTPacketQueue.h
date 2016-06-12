//
//  IJTPacketQueue.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/types.h>
#import <pcap.h>

@interface IJTPacketQueue : NSObject

typedef struct Packet_t packet_t;
struct Packet_t {
    u_char content[PACKET_MAX];
    struct pcap_pkthdr header;
    struct Packet_t *next;
};

- (id)initQueue;
- (void)dealloc;

/**
 * 加入封包到佇列中
 * @param header 要加入的封包表頭資訊
 * @param content 要加入的封包內容
 */
- (void)enqueuePacketHeader:(const struct pcap_pkthdr *)header packetContent:(const u_char *)content;

/**
 * 從佇列中取出封包並移除該節點
 * @param packet 封包結構
 * @param 成功傳回YES, 失敗NO
 */
- (BOOL)dequeuePacketHeader:(packet_t *)packet;

/**
 * 釋放所有佇列
 */
- (void)freeQueue;

@end
