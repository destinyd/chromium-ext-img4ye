// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To make sure we can uniquely identify each screenshot tab, add an id as a
// query param to the url that displays the screenshot.
// Note: It's OK that this is a global variable (and not in localStorage),
// because the event page will stay open as long as any screenshot tabs are
// open.
var id = 100;

var Capturer = {
    canvas: document.createElement("canvas"),
    yPos: 0,
    scrollHeight: 0,
    scrollWidth: 0,
    fetchPageSize: function (tabId){
        var self = this;
        chrome.tabs.sendMessage(tabId, {task: 'fetchPageSize'}, self.onResponseVisibleSize);
        // this.captureVisibleBlock();
    },
    scrollPage: function(tabId, x, y){
        var self = this;
        chrome.tabs.sendMessage(tabId, {task: 'scrollPage', x: x, y: y}, self.onScrollDone);
    },
    onScrollDone: function(resMsg) {
        setTimeout(function(){
            Capturer.captureVisibleBlock();
        }, 200)
    },
    startCapture: function(){
        // scroll to top
        
        this.yPos = 0;
        this.scrollPage(this.tabId, 0, -1 * this.scrollHeight);
        // self.postImg();
    },
    onResponseVisibleSize: function (pageSize) {
        Capturer.scrollWidth = pageSize.scrollWidth;
        Capturer.scrollHeight = pageSize.scrollHeight;
        Capturer.clientWidth = pageSize.clientWidth;
        Capturer.clientHeight = pageSize.clientHeight;

        Capturer.canvas.width = pageSize.scrollWidth;
        Capturer.canvas.height = pageSize.scrollHeight;

        Capturer.startCapture();
    },
    captureVisibleBlock: function (w, h){
        var self = this;
        var width = w || self.clientWidth;
        var height = h || self.clientHeight;

        chrome.tabs.captureVisibleTab(null, function(img) {
            var blockImg = new Image();
            var canvas = self.canvas;

            if (Capturer.yPos + Capturer.clientHeight >= Capturer.scrollHeight) {
                blockImg.onload = function() {
                    var ctx = canvas.getContext("2d");
                    var y = Capturer.clientHeight - Capturer.scrollHeight % Capturer.clientHeight;
                    ctx.drawImage(blockImg, 0, 0, width, height, 0, self.yPos - y, width, height);
                    Capturer.postImg();
                };
            } else {
                blockImg.onload = function() {
                    var ctx = canvas.getContext("2d");
                    ctx.drawImage(blockImg, 0, 0, width, height, 0, Capturer.yPos, width, height);
                    Capturer.yPos += Capturer.clientHeight;
                    self.scrollPage(self.tabId, 0, Capturer.clientHeight);
                };
            }

            blockImg.src = img;
        });

    },
    scrollToNextBlock: function () {
        
    },
    postImg: function () {
        var canvas = Capturer.canvas;
        var screenshotUrl = canvas.toDataURL();
        var viewTabUrl = chrome.extension.getURL('screenshot.html?id=' + id++);
        window.upload_url = screenshotUrl
        chrome.storage.local.set({
              'src': screenshotUrl
            }, function() {
              return window.open(window.extension_base_url + "edit.html", "_blank");
            });
    }
};
function takeScreenshot() {
    var tabId = chrome.tabs.getSelected(function(tab){
        Capturer.tabWin = window;
        Capturer.tabId = tab.id;
        Capturer.fetchPageSize(tab.id);
    });
}

// Listen for a click on the camera icon.  On that click, take a screenshot.
//chrome.browserAction.onClicked.addListener(function(tab) {
    //takeScreenshot();
//});
