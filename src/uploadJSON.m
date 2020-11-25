function serverResponse = uploadJSON(json_txt)
    writeKey = 'BJ0V9DMXEXXEH6QT';
    channelID = 1236394;
    serverResponse = thingSpeakWrite(channelID, {0, json_txt}, 'WriteKey', writeKey);
    pause(15);
end