**Release notes for JAMP client library**
=====================================
**2013-10-14**
========

Changes
-------
 - hide unnecessary JAMP message details from Channel interface
 - added support for unmarshaling of json maps to simple classes
 - added ChannelManager for custom connection error logic
 - use dart:convert instead of dart:json for JSON

Roadmap
-------
 - add support for automatic json serialization of classes passed as arguments
 - add support for unmarshaling of complex classes
 - clean up configuration of http ajax polling
 - fix subscribe/callbacks
 - ???

**Usage notes for latest release**
==============================
1.  Simple query:
    Channel channel = Channel.create(url);
    Future<Object> future = channel.query(serviceName, methodName);

    future.then((Object obj)) {
      bool result = obj as bool;
      ...
    }

2.  Passing args:

    Future<Object> future = channel.query(serviceName, methodName, args : [123, "foo"]);
    ...

3.  Automatic unmarshaling of json maps to simple objects.

    User user = new User();
    Future<Object> future = channel.query(serviceName, methodName, resultObject : user);

    future.then((Object obj) {
      User user2 = obj as User;
    
      if (user2 != null) {
        assert(identical(user, user2));
      }
    });

4.  Using send (without expecting a response) instead of query:

    Future<bool> future = channel.send(serviceName, methodName);
  
    future.then((bool result)) {
      print("sent successfully"); // result should always be true for "then"
    });

5.  Custom connection management:

    Channel channel = Channel.create(url);
    channel.manager = new MyChannelManager(channel);
  
    class MyChannelManager extends ChannelManager {
      void onOpen() {
        // called when the channel is opened/reopened
      }
    
      void onClose(Exception e) {
        // called when the channel is closed unexpectedly
      }
    
      void onError(Exception e) {
        // called when there is an unspecified error with the channel
      }
    }
  