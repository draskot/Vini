package hr.irb.cir;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class PDBChainNameSupstitutor {
    private static List<String> fileContents = new ArrayList<String>();
    private static String fileName = null;
    private static String originalChainName="A";
    private static String newChainName="B";
    private static String newFileName = null;
    private static boolean isAtom = true;
    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            System.out.println("Usage: java -jar PDBChainNameSupstitutor.jar  <fileName> <chainID1> <chainID2> -<h/a>");
            System.out.println(" -h make substitution in HETATM lines");
            System.out.println(" -a make substitution in ATOM lines");
            return;
        }

        fileName = args[0];
        if (! new File(fileName).exists()) {
            throw new Exception("File doesn't exist");
        }


        originalChainName = args[1];
        newChainName = args[2];
        newFileName =  fileName+"_"+originalChainName + "_to_" + newChainName + ".pdb";
        if (args[3].isEmpty()){
            isAtom=true;
        }else{
            isAtom=(args[3].equalsIgnoreCase("-a"))?true:false;
        }

        LoadFile(fileName);
        substituteChains();
        writeToNewFile();
    }
    private static void LoadFile(String fileName){
        fileContents = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(fileName))) {
            String line;
            while ((line = br.readLine()) != null) {
                fileContents.add(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private static void substituteChains(){
        List<String> newLines = new ArrayList<String>();
        for (int i = 0; i < fileContents.size(); i++) {
            String line = fileContents.get(i);
            String lineName=(isAtom)?"ATOM":"HETATM";
            if (line.startsWith(lineName)) {
                String chainName = line.substring(21, 22);
                if (chainName.equals(originalChainName)) {
                    line = line.substring(0, 21) + newChainName + line.substring(22);
                }
            }
            newLines.add(line);
        }
        fileContents=newLines;
    }
    private static void writeToNewFile(){
        try (BufferedWriter bw = new BufferedWriter(new FileWriter(newFileName))) {
            for (String line : fileContents) {
                bw.write(line);
                bw.newLine();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
