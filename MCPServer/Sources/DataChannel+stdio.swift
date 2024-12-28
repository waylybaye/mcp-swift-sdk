import Foundation
import JSONRPC

extension DataChannel {

  /// A `DataChannel` that uses the process stdio.
  ///
  /// Note: this is similar to `DataChannel.stdioPipe` but it ensures the data is flushed when written.
  public static func stdio() -> DataChannel {
    let writeHandler: DataChannel.WriteHandler = { data in
      // TODO: upstream this to JSONRPC
      var data = data
      data.append(contentsOf: [UInt8(ascii: "\n")])
      FileHandle.standardOutput.write(data)
    }

    return DataChannel(writeHandler: writeHandler, dataSequence: FileHandle.standardInput.dataStream)
  }
}
