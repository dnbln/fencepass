# Running The Store Buffering Test

Run the Store Buffering test in two stages. First, build and run the original program from `sb.c` to get the baseline Store Buffering count. Second, run the pass on `sb.ll` to produce the transformed LLVM IR. Build an executable from that transformed IR, and run it too. 

Comparing the two printed counts shows whether Store Buffering still happens after the pass. Store Buffering is allowed in the TSO and PSO models. This serves to separate them from the SC model.

Note: The test aims to find one of the positive scenarios when reorderings do happen. Due to the non-deterrministic nature of parallel programs, there is also a risk that it will show no reorderings happening even on a correct pass. To mitigate for this, the code gets run a large number of times (1000000), but even then, it cannot be guaranteed that the pass is incorrect.