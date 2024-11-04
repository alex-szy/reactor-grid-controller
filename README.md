## SkyFactory 3 Power Grid Control System
These are the code files for an OpenComputers script to manage and control my power grid in my Minecraft SkyFactory 3 world.
The grid consists of the following:
- 16 Extreme Reactors Turbines
- 1 Extreme Reactors Reactor
- 1 Rainbow Generator
- 1 Draconic Evolution Energy Core

### Grid Controller
- The grid tries to keep the energy core at between 25% to 30% full.
- Every second or so, the grid controller polls the energy core for its stored energy. It then determines the discharge rate between the polling intervals.
- Based on this discharge rate, the grid controller and requests for a number of turbines from the turbine controller to attain a minimal discharge rate.
- Once the core discharges to 25%, the grid computer then requests for just enough turbines from the turbine controller to attain a minimal charge rate, slowly charging the core back to 30%. The cycle then repeats itself.
- If there is a spike in power consumption and the turbines are not able to keep up with the demand, the system will enter an emergency charging state when the core discharges to 20%.
- In this state, the rainbow generator will run, and cut-out when the core charges back to 30%, after which the system resumes normal operation.

### Turbine Controller
- The turbine controller receives requests from the grid controller for a certain number of turbines.
- It automatically tries to start and keep all connected turbines running in their optimum RPM range.
- It disengages the generator if the RPM drops too low, and cuts off the steam supply if the RPM rises too high.

***Inspired by [BRGC by XyFreak](https://tenyx.de/brgc/)***