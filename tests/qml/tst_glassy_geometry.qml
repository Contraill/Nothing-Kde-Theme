import QtQuick
import QtTest
import "../../plasma/aurorae/org.glassy.decoration/contents/ui/Geometry.js" as Geometry
TestCase {
    name: "GlassyGeometry"
    function test_parallel_corner_insets_data() {
        let cases=[];
        for(const radius of [0,10,24]) for(const border of [0,1,2]) for(const bottom of [false,true])
            cases.push({tag:radius+"/"+border+"/"+bottom, radius:radius, border:border, bottom:bottom});
        return cases;
    }
    function test_parallel_corner_insets(data) {
        const arcs=[];
        const c={beginPath(){},moveTo(){},lineTo(){},closePath(){},arc(x,y,r,a,b){arcs.push([x,y,r,a,b]);}};
        Geometry.path(c,180,100,data.radius,data.border/2,data.bottom);
        if(data.radius===0) compare(arcs.length,0);
        else {
            compare(arcs.length,data.bottom ? 4 : 2);
            compare(arcs[0][0],data.radius); compare(arcs[0][1],data.radius);
            compare(arcs[0][2],data.radius-data.border/2);
            compare(arcs[1][0],180-data.radius);
            if(data.bottom) {
                compare(arcs[2][0],180-data.radius); compare(arcs[2][1],100-data.radius);
                compare(arcs[3][0],data.radius); compare(arcs[3][1],100-data.radius);
                compare(arcs[2][2],arcs[0][2]); compare(arcs[3][2],arcs[0][2]);
            }
        }
    }
}
