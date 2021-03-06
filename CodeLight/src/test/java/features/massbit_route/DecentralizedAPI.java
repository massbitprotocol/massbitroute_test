package features.massbit_route;

import net.serenitybdd.junit.runners.SerenityParameterizedRunner;
import net.thucydides.core.annotations.Steps;
import net.thucydides.core.annotations.Title;
import net.thucydides.junit.annotations.TestData;
import net.thucydides.junit.annotations.UseTestDataFrom;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import steps.UtilSteps;
import steps.api_massbit_route.Decentralized_API_Steps;
import utilities.DataCSV;
import utilities.Log;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;


@RunWith(SerenityParameterizedRunner.class)
//@UseTestDataFrom(value="data/api_info.csv")
public class DecentralizedAPI {

    enum Provider{MASSBIT,INFURA,GETBLOCK,QUICKNODE,CUSTOM,MASSBIT_EDIT,INFURA_EDIT,GETBLOCK_EDIT,QUICKNODE_EDIT,CUSTOM_EDIT}

    @TestData
    public static Collection<Object[]> testData() throws Exception {
        Object[][] data = DataCSV.getAllDataCSV("data/api_info.csv");
        return Arrays.asList(data);
    }

    private String name;
    private String blockchain;
    private String network;

    public DecentralizedAPI(String name, String blockchain, String network){
        this.name = name;
        this.blockchain = blockchain;
        this.network = network;
    }


    @Before
    public void prepareForTest() throws IOException, InterruptedException {
        decentralized_api_steps.should_be_able_to_say_hello();
        decentralized_api_steps.should_be_able_to_login();
    }

    @Steps
    Decentralized_API_Steps decentralized_api_steps;

    @Test
    public void create_api_key_without_name(){
        decentralized_api_steps.should_be_able_to_create_api("", blockchain, network);
    }

    @Test
    public void create_api_key_without_blockchain(){
        decentralized_api_steps.should_be_able_to_create_api(name, "", network);
    }

    @Test
    public void create_api_key(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
    }

    @Test
    public void change_request_unlimited_per_day(){
        decentralized_api_steps.should_be_able_to_update_api_request_limit_per_day_to_unlimited();
    }

    @Test
    public void add_entrypoint_massbit(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.MASSBIT.toString());
    }

    @Test
    public void add_entrypoint_infura(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.INFURA.toString());
    }

    @Test
    public void add_entrypoint_getblock(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.GETBLOCK.toString());
    }

    @Test
    public void add_entrypoint_quicknode(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.QUICKNODE.toString());
    }

    @Test
    public void add_entrypoint_custom(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.CUSTOM.toString());
    }

    @Test
    public void edit_entrypoint_massbit(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.MASSBIT.toString())
                               .should_be_able_to_edit_entrypoint(Provider.MASSBIT_EDIT.toString());
    }

    @Test
    public void edit_entrypoint_infura(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.INFURA.toString())
                               .should_be_able_to_edit_entrypoint(Provider.INFURA_EDIT.toString());
    }

    @Test
    public void edit_entrypoint_getblock(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.GETBLOCK.toString())
                               .should_be_able_to_edit_entrypoint(Provider.GETBLOCK_EDIT.toString());
    }

    @Test
    public void edit_entrypoint_quicknode(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.QUICKNODE.toString())
                               .should_be_able_to_edit_entrypoint(Provider.QUICKNODE_EDIT.toString());
    }

    @Test
    public void edit_entrypoint_custom(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.CUSTOM.toString())
                               .should_be_able_to_edit_entrypoint(Provider.CUSTOM_EDIT.toString());
    }

    @Test
    public void delete_entrypoint_massbit(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.MASSBIT.toString());
        decentralized_api_steps.should_be_able_to_delete_entrypoint(Provider.MASSBIT.toString());
    }

    @Test
    public void delete_entrypoint_infura(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.INFURA.toString());
        decentralized_api_steps.should_be_able_to_delete_entrypoint(Provider.INFURA.toString());
    }

    @Test
    public void delete_entrypoint_getblock(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.GETBLOCK.toString());
        decentralized_api_steps.should_be_able_to_delete_entrypoint(Provider.GETBLOCK.toString());
    }

    @Test
    public void delete_entrypoint_quicknode(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.QUICKNODE.toString());
        decentralized_api_steps.should_be_able_to_delete_entrypoint(Provider.QUICKNODE.toString());
    }

    @Test
    public void delete_entrypoint_custom(){
        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint(Provider.CUSTOM.toString());
        decentralized_api_steps.should_be_able_to_delete_entrypoint(Provider.CUSTOM.toString());
    }



    @Test
    public void massbit_route_call_api() throws IOException, InterruptedException {

        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint("MASSBIT");

        for(int i = 0; i < 2; i++){
            Thread.sleep(5000);
            decentralized_api_steps.should_be_able_to_send_api_request(blockchain);
        }

    }

    @Test
    public void massbit_route_call_api_2() throws IOException, InterruptedException {

        decentralized_api_steps.should_be_able_to_create_api(name, blockchain, network);
        decentralized_api_steps.should_be_able_to_add_entrypoint("MASSBIT");

        for(int i = 0; i < 2; i++){
            Thread.sleep(5000);
            decentralized_api_steps.should_be_able_to_send_api_request(blockchain);
        }

    }

    @Test
    public void massbit_route_call_api_3() throws IOException, InterruptedException {

        decentralized_api_steps.should_be_able_to_update_api_request_limit_per_day_to_unlimited();

    }

//    @Test
//    public void massbit_route_api_testing() throws IOException, InterruptedException {
//        Log.info("----------- Start Decentralized API test ----------");
//        decentralized_api_steps.should_be_able_to_say_hello()
//                               .should_be_able_to_login()
//                               .should_be_able_to_create_api(name, blockchain, network)
//                               .should_be_able_to_update_api_request_limit_per_day_to_unlimited()
//                               .should_be_able_to_update_api_request_limit_per_day(99999999)
//                               .should_be_able_to_update_api_request_limit_per_day(-2)
//                               .should_be_able_to_update_api_request_limit_per_day(1)
//                               .should_be_able_to_update_api_request_limit_per_sec(999999)
//                               .should_be_able_to_update_api_request_limit_per_sec(0)
//                               .should_be_able_to_update_api_request_limit_per_sec(-2)
//                               .should_be_able_to_update_api_request_limit_per_sec(1)
////                               .should_be_able_to_update_allowlist_api_request_method()
////                               .should_be_able_to_get_api_list()
//                               .should_be_able_to_add_entrypoint("MASSBIT")
//                               .should_be_able_to_send_api_request(blockchain)
//                               .should_be_able_to_edit_entrypoint("MASSBIT_EDIT")
//                               .should_be_able_to_delete_entrypoint("DELETE")
//                               .should_be_able_to_add_entrypoint("INFURA")
//                               .should_be_able_to_send_api_request(blockchain)
//                               .should_be_able_to_edit_entrypoint("INFURA_EDIT")
//                               .should_be_able_to_delete_entrypoint("DELETE")
//                               .should_be_able_to_add_entrypoint("GETBLOCK")
//                               .should_be_able_to_send_api_request(blockchain)
//                               .should_be_able_to_edit_entrypoint("GETBLOCK_EDIT")
//                               .should_be_able_to_delete_entrypoint("DELETE");
////                               .should_be_able_to_add_entrypoint("QUICKNODE")
////                               .should_be_able_to_send_api_request(blockchain)
////                               .should_be_able_to_edit_entrypoint("QUICKNODE_EDIT")
////                               .should_be_able_to_delete_entrypoint("DELETE")
////                               .should_be_able_to_add_entrypoint("CUSTOM")
////                               .should_be_able_to_send_api_request(blockchain)
////                               .should_be_able_to_edit_entrypoint("CUSTOM_EDIT")
////                               .should_be_able_to_delete_entrypoint("DELETE");
//
//    }

}
