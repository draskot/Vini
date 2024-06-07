import hr.irb.cir.PDBChainNameSupstitutor;
import org.testng.annotations.Test;

public class TestSubstitute {
    public static String filePath="c:\\Users\\IRB\\Documents\\projekti\\PDBChainNameSupstitutor\\1aki.pdb";
    public static String filePathHetam="c:\\Users\\IRB\\Documents\\projekti\\PDBChainNameSupstitutor\\Everolimus.pdb";

    public static String fileWithErrors = "c:\\Users\\IRB\\Documents\\projekti\\vini\\PDBChainNameSupstitutor\\tmp\\Bevacizumab.pdb";

    @Test
    public void testFileWithErrors() throws Exception {
//        PDBChainNameSupstitutor.main(new String[]{fileWithErrors,"A","B","-h"});
        PDBChainNameSupstitutor.main(new String[]{fileWithErrors,"B","D","-a"});
    }

//    @Test
    public void testConvertFile() throws Exception {
        PDBChainNameSupstitutor.main(new String[]{filePath,"A","B"});
    }

//    @Test
    public void testConvertFileHetatmLines() throws Exception {
        PDBChainNameSupstitutor.main(new String[]{filePathHetam," ","X","-h"});
    }

}
