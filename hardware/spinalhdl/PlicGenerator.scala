import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axilite._
import spinal.lib.bus.amba3.apb._
import spinal.lib.misc.plic._

case class PlicConfig(
  sourceCount: Int,
  targetCount: Int,
  priorityWidth: Int = 2,
  busType: String = "axilite"
)

class PlicVerilog(config: PlicConfig) extends Component {
  val plicMapping = PlicMapping.sifive
  
  val io = new Bundle {
    val sources = in Bits (config.sourceCount bits)
    val targets = out Bits (config.targetCount bits)
    
    val axilite = (config.busType == "axilite") generate slave(AxiLite4(AxiLite4Config(22, 32)))
    val apb     = (config.busType == "apb")     generate slave(Apb3(Apb3Config(22, 32)))
  }

  val gateways = (for ((source, id) <- (io.sources.asBools, 1 to config.sourceCount).zipped) yield PlicGatewayActiveHigh(
    source = source,
    id = id,
    priorityWidth = config.priorityWidth
  )).toSeq

  val targets = for (i <- 0 until config.targetCount) yield PlicTarget(
    id = i,
    gateways = gateways,
    priorityWidth = config.priorityWidth
  )

  io.targets := targets.map(_.iep).asBits

  val bus = config.busType match {
    case "axilite" => new AxiLite4SlaveFactory(io.axilite)
    case "apb"     => new Apb3SlaveFactory(io.apb, selId = 0)
  }

  val mapping = PlicMapper(bus, plicMapping)(
    gateways = gateways,
    targets = targets
  )
}

object PlicGenerator extends App {
  println("Starting PlicGenerator...")
  val config = PlicConfig(
    sourceCount = 31,
    targetCount = 2,
    priorityWidth = 2,
    busType = "axilite"
  )
  
  SpinalConfig(
    targetDirectory = "gen",
    defaultConfigForClockDomains = ClockDomainConfig(resetActiveLevel = LOW)
  ).generateVerilog(new PlicVerilog(config))
  println("PlicGenerator finished.")
}
