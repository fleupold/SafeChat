SafeChat.IM
========

SafeChat.IM offers encryption for Facebook Chats to everybody with a simple-to-use App that automates message encryption and integrates into your social network seamlessly.

## How to set it up

Once you installed the app, all you need to do is connect with your Facebook account and set up a passphrase, which will be used to generate your cryptographic key (press the settings button in the upper left corner to get there). Make sure to remember the passphrase, as you will need it, if you want to decrypt messages on a different device. If you have already set up a different passphrase on a different device, we will ask you if you want to override that old passphrase, as we can only store one public key per account on our server. If you chose to override the old key, all messages that have been encrypted using this old key will no longer be readable to you or the sender.

If everything is ready to go, your configuration screen should like this:

![Configruation screen with encryption set up](http://github.com/fleupold/SafeChat/raw/master/Screenshots/small/configuration.png)

## Messaging

Chatting works the same as with other messaging apps. The only difference is, that if you chat with a friend, who is using the app as well, all messages will be encrypted and only SafeChat.IM can show it in plaintext. The app finds SafeChat.IM compatible friends automatically and indicated that a messages is encrypted with a lock next to the speech bubble.

![Encrypted Messages are indicated with a lock](http://github.com/fleupold/SafeChat/raw/master/Screenshots/small/message_detail.png)

Your private  key is stored encrypted on your device. No messages are ever transmitted to any of our servers. Everything is still hosted on Facebook. 

## Limitations
Due to limitations in the Facebook XMPP support, we currently cannot provide the following features:
* Writing messages in group chats
* Sending 'read receipts' (this might be considered a feature. You can read messages without letting your friend know you have already seen it)

Notifications only work if you allow the app to run in background mode. Since we do not store any messages, we cannot send push notifications. Instead the app refreshes in the background about every 10 minutes and fetches the newest messages.

## More information

For more information read the [FAQ page](wiki/FAQ#how-can-validate-the-promised-privacy-and-encryption) in the wiki or drop us an e-mail at info@safechat.im.
