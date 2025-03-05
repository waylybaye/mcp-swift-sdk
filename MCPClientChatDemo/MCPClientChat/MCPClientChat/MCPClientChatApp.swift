//
//  MCPClientChatApp.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import SwiftAnthropic
import SwiftUI

@main
struct MCPClientChatApp: App {

  @State private var chatManager = ChatNonStreamManager(
    service: AnthropicServiceFactory.service(
      apiKey: "YOUR_API_KEY",
      betaHeaders: nil,
      debugEnabled: true),
    mcpLLMClient: GithubMCPClient())

  var body: some Scene {
    WindowGroup {
      ChatView(chatManager: chatManager)
        .toolbar(removing: .title)
        .containerBackground(
          .thinMaterial, for: .window)
        .toolbarBackgroundVisibility(
          .hidden, for: .windowToolbar)
    }
    .windowStyle(.hiddenTitleBar)
  }
}
