# Extraction #

  1. Disabling Fog
    * Find the main script file for the map in one of the .pk3 files.
      * EX: `COD_INSTALL\uo\uomappack00.pk3 -> maps\mp\mp_uo_hurtgen.gsc`
    * Edit the file and find the function call that sets the fog.
      * EX: `setCullFog(0, 3200, .32, .36, .40, 0);`
    * Replace the values with those from a low fog level like carentan:
      * EX: `setCullFog(0, 16500, 0.7, 0.85, 1.0, 0);`
      * [Full Function Documentation](http://www.modsonwiki.com/index.php/Call_of_Duty:_Script_-_mapname.gsc#setCullFog)
    * Save the file to its original path either inside the .pk3 file or in the cod-stats mod directory.
    * When the map is loaded the fog values should be overridden.
  1. Set spectator to approximately 5000 units or more above the map in order to acquire the entire map in one screen shot
  1. Using image processing software increase the size to as close to 4096x4096 in either the x or y direction as possible
  1. Fly around in spectator mode and grab 3 locations on the map (corners of specific buildings, etc...) spreading them out as much as possible over the map
  1. Find out what pixel x/y those locations correspond to using Paint (gives xy positions) in the 4096x4096 padded image
  1. Use python to solve system of linear equations using matrix algebra
  1. Use the result to give us the coordinate transformation (table of transformation equations for specific maps is located below)
  1. Several pixel errors can be expected for maps with large elevation changes
  1. Map scale seems to be about 0.019685 meters or 0.0645833333 feet per 1 map unit.
    * Based on a [Willy's Jeep](http://en.wikipedia.org/wiki/Willys_MB) width of 62in. and a game model width of 80 map units.

# Processing #

  1. This process simply needs to be replicated for all maps and all portions of the map
  1. Slice the overview image into individual tiles based on the Google Map's convention.
    * This software may be helpful: [Tile Cutter](http://mapki.com/wiki/Automatic_Tile_Cutter).
    * More information on creating map tiles: [Microsoft MapCruncher](http://www.bdcc.co.uk/GoogleCrunch/Crunch.htm).

# Display #

  1. Display the map data similar to the public Google Maps site.
  1. The maps must work without internet access.
    * [OpenLayers](http://openlayers.org/) should be able to do everything we need.
    * [Custom Tile Example](http://trac.openlayers.org/wiki/UsingCustomTiles)
  1. An overview of the process is described [here](http://www.alistapart.com/articles/takecontrolofyourmaps).
  1. Here is a [screenshot](http://img389.imageshack.us/img389/7735/map.jpg) of a demo I made using non-earth based tiles.

# Coordinate Conversion Table #
The following table provides equations to convert from the CoD coordinate system to the map tile pixel coordinate system.
| **Map** | **X-Pixel** | **Y-Pixel** | **Game Name** | **Verified** |
|:--------|:------------|:------------|:--------------|:-------------|
| Carentan | `3036.99 - 0.0005 * x - 0.748 * y` | `2405.06 - 0.746 * x + 0.0149 * y` | mp\_uo\_carentan | X |
| Harbor | `-3756.58 - 0.6532 * x + 0.01429 * y` | `6871.9 + 0.00896 * x + 0.6459 * y` | mp\_uo\_harbor | X |
| Kursk | `471.294 - 0.00459 * x - 0.1852 * y` | `1963.22 - 0.1859 * x + 0.002067 * y` | mp\_kursk | X |
| Dawnville | `8698.9 + 0.4451 * x + 0.39842 * y` | `-5625.61 + 0.3846 * x - 0.44599 * y` | mp\_uo\_dawnville | X |
| Hurtgen | `1670.37 + 0.35984 * x + 0.005116 * y` | `1699.43 + 0.002471 * x - 0.36013 * y` | mp\_uo\_hurtgen | X |
| Peaks | `2619.06 + 0.5361 * x - 0.01583 * y` | `2222.38 - 0.002845 * x - 0.5383 * y` | mp\_peaks | X |
| Foy | `2062.27 + 0.001055 * x + 0.2315 * y` | `2158.63 + 0.2345*x + 0.000368 * y` | mp\_foy | X |
| Stanjel | `1706.93 - 0.5531 * x - 0.01042 * y` | `752.86 - 0.01206 * x + 0.56215 * y` | mp\_uo\_stanjel | X |
| Arnhem | `2191.49 + 0.6545 * x - 0.003142 * y` | `2703.83 + 0.00107 * x - 0.6466 * y` | mp\_arnhem | X |
| POW Camp | `1249.65 - 0.0051 * x + 0.5042 * y` | `2181.31 + 0.5002 * x + 0.00173 * y` | mp\_uo\_powcamp | X |
| Berlin | `3345.23 + 0.4493 * x + 0.000073669 * y` | `3343.8 - 0.002766 * x - 0.4605 * y` | mp\_berlin | X |
| Bocage | `1271.94 + 0.02848 * x + 0.2354 * y` | `2352.14 + 0.2367 * x - 0.023267 * y` | mp\_bocage | X |
| Brecourt | `1801.21 + 0.447 * x - 0.003862 * y` | `1431.46 + 0.157 * x - 0.4881 * y` | mp\_brecourt | X |
| Cassino | `746.29 + 0.4168 * x - 0.001304 * y` | `1656.26 - 0.0009419 * x - 0.4177 * y` | mp\_cassino | X |
| Chateau | `1640.29 + 1.0396 * x - 0.008571 * y` | `3033.23 - 0.005201 * x - 1.0373 * y` | mp\_chateau | X |
| Neuville | `10673.55 + 0.6144 * x + 0.01809 * y` | `4396.89 - 0.001637 * x - 0.6379 * y` | mp\_neuville | X |
| Italy | `2202.59 + 0.002778 * x + 0.2025 * y` | `1973.99 + 0.2021 * x + 0.001427 * y` | mp\_italy | X |
| Depot | `2006.08 - 0.00362 * x + 0.57603 * y` | `2752.87 + 0.5688 * x + 0.004178 * y` | mp\_uo\_depot | X |
| Streets | `-671.16 + 0.003213 * x - 0.4655 * y` | `2809.23 - 0.4742 * x + 0.001135 * y` | mp\_streets | ! |
| Enclave | `1909.75 - 0.3634 * x - 0.002011 * y` | `2505.98 - 0.001483 * x + 0.3604 * y` | enclave | X |
| Jeep Arena | `2146.47 - 0.002134 * x - 0.2482 * y` | `1969.07 - 0.2472 * x + 0.002444 * y` | jeeparena | X |
| Pavlov | `7308.46 - 0.001906 * x - 0.5576 * y` | `-2982.32 - 0.5549 * x - 0.002028 * y` | mp\_pavlov | X |
| Ponyri | `1399.05 - 0.00007585 * x - 0.1922 * y` | `2559.21 - 0.1919 * x + 0.003295 * y` | mp\_ponyri | X |
| Railyard | `1564.88 + 0.01408 * x + 0.523 * y` | `2697.46 + 0.5087 * x + 0.001226 * y` | mp\_railyard | X |
| Reserves | `1983.35 - 0.002727 * x + 0.5899 * y` | `1660.26 + 0.5875 * x + 0.002758 * y` | reserves | X |
| Rhine Valley | `3236.26 - 0.1621 * x + 0.109 * y` | `3035.92 + 0.1096 * x + 0.1499 * y` | mp\_rhinevalley | X |
| Rocket | `-2277.55 + 0.285 * x + 0.3392 * y` | `-25.95 + 0.3367 - 0.2829 * y` | mp\_rocket | X |
| Ship | `497.6 + 0.3962 * x - 0.2014 * y` | `2145.9 - 0.0003552 * x - 0.4154 * y` | mp\_ship | ! |
| Sicily | `619.07 - 0.3657 * x + 0.09822 * y` | `1799.51 + 0.09403 * x + 0.3694 * y` | mp\_sicily | ! |
| Stalingrad | `-493.67 + 0.716 * x - 0.003368 * y` | `1313.59 + 0.00728 * x - 0.706 * y` | mp\_stalingrad | X |
| WarehouseFun | `-196.52 - 0.005807 * x + 1.688 * y` | `5140.77 + 1.688 * x + 0.002167 * y` | warehousefun |  |