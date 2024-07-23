import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ProcessBuilder.Redirect;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Paths;

public class RunExp {
  public static void main(String[] args) throws IOException, InterruptedException {
    if (args.length != 2)
      fatal("Usage: java RunExp <RLC> <count> where <RLC> is the path to the ReferenceLanguageCorpora and <count> is the number of iterations per experiment");
    new RunExp(args[0], Integer.parseInt(args[1]));
  }

  RunExp(String rlc, int count) throws IOException, InterruptedException {
    System.out.println("RLC experimental framework running on " + rlc);
    Files.deleteIfExists(Paths.get("log.csv"));
    File log = new File("log.csv");
    var tools = getFiles(rlc + "/experiments/try/tools");
    var languages = getFiles(rlc + "/languages");
    var scripts = getFiles(rlc + "/experiments/try/scripts");
    if (tools == null || tools.length == 0) fatal("No tools found " + rlc + "/experiments/try/tools");
    if (languages == null || languages.length == 0) fatal("No languages found in " + rlc + "/languages");
    if (scripts == null || scripts.length == 0) fatal("No scripts found in " + rlc + "/experiments/try/scripts");
    for (var t : tools) {
      final boolean isARTTool = t.getName().startsWith("art");
      for (var s : scripts) {
        if ((isARTTool && !s.getName().endsWith("art")) || (!isARTTool && !s.getName().endsWith("gtb"))) continue; // script and tool mismatch
        for (var l : languages)
          for (var g : getFiles(l + "/grammar"))
            for (var c : getFiles(l + "/corpus"))
              for (var gg : getFiles(g + "/tok")) {
                if ((isARTTool && !gg.getName().endsWith("art")) || (!isARTTool && !gg.getName().endsWith("gtb"))) continue; // grammar and tool mismatch
                fileCat("test." + (isARTTool ? "art" : "gtb"), gg, s);
                for (var cc : getFiles(c + "/tok")) {
                  fileCat("test.str", cc);
                  System.out.print(t.getName() + " " + s.getName() + " " + g.getName() + " " + gg.getName());
                  for (int i = 0; i < count; i++) {
                    System.out.print(" " + i);
                    if (isARTTool)
                      execute(log, "java", "-jar", t.toString(), "noFX", "test.art");
                    else
                      execute(log, t.toString(), "test.gtb");
                  }
                  System.out.println();
                }
              }
      }
    }
  }

  private void fileCat(String dstFilename, File... files) throws IOException {
    FileChannel dst = new FileOutputStream(dstFilename).getChannel();
    for (var file : files) {
      FileChannel src = new FileInputStream(file).getChannel();
      src.transferTo(0, src.size(), dst);
      src.close();
    }
    dst.close();
  }

  private void execute(File log, String... command) throws IOException, InterruptedException {
    ProcessBuilder pb = new ProcessBuilder(command);
    pb.redirectErrorStream(true);
    pb.redirectOutput(Redirect.appendTo(log));
    Process p = pb.start();
    p.waitFor();
  }

  static File[] empty = new File[0];

  static File[] getFiles(String directory) {
    var tmp = new File(directory).listFiles();
    return tmp == null ? empty : tmp;
  }

  static void fatal(String msg) {
    System.err.println(msg);
    System.exit(0);
  }
}
