//
//  GithubMCPClient.swift
//  MCPClientChat
//
//  Created by James Rochabrun on 3/3/25.
//

import Foundation
import MCPClient
import SwiftUI

final class GIthubMCPClient: MCPLLMClient {
   
   /// Intentionally force unwrapping for demo, if cleint is nil this demo does not have any purpose.
   var client: MCPClient?
   
   init() {
      Task {
         do {
            var customEnv = ProcessInfo.processInfo.environment
            customEnv["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (customEnv["PATH"] ?? "")
            //    customEnv["GITHUB_PERSONAL_ACCESS_TOKEN"] = "YOUR_GITHUB_PERSONAL_TOKEN" // Needed for write operations.
            self.client = try await MCPClient(
               info: .init(name: "GIthubMCPClient", version: "1.0.0"),
               transport: .stdioProcess(
                  "npx",
                  args: ["-y", "@modelcontextprotocol/server-github"],
                  env: customEnv,
                  verbose: true
               ),
               capabilities: .init()
            )
         } catch {
            print("Failed to initialize MCPClient: \(error)")
         }
      }
   }
}
