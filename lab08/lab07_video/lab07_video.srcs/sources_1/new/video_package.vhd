/*
With generic package in Vivavo, we need to inst. package in different file
*/
library ieee;

package video_package is new work.video_package_generic
    generic map(
        COLOR_WIDTH     => 4,
        FRAME_CNT_WIDTH => 6
    );
