const SVG_BOX = {
    width: 500, height: 700,
    top: 30, left: 50, bottom: 30, right: 50
}

const SPACE_WIDTH = 5;
const ZERO_OPACITY = 1e-6;
const POPUP_OFFSET = 5;
const TOOLTIP_MARGIN = 10;

const BEFORE_VAL_X = 300;
const LINE_X1 = BEFORE_VAL_X + 5;
const BEFORE_LABEL_X = BEFORE_VAL_X - 25;

const AFTER_VAL_X = 500;
const LINE_X2 = AFTER_VAL_X - 5;
const AFTER_LABEL_X = AFTER_VAL_X + 25;

const AXIS_LABEL_OFFSET = 30;

let t = d3.transition()
    .duration(750);

let yScale = d3.scaleLinear()
    .range([0.8 * SVG_BOX.height, SVG_BOX.top]);

let timelineScale = d3.scaleLinear()
    .range([0.8 * SVG_BOX.height, 0]);

let timelineSnap = d3.scaleThreshold();

let svg = d3.select("div#vis").append("svg")
    .attr("class", "slopegraph")
    .attr("width", SVG_BOX.width)
    .attr("height", SVG_BOX.height);

svg.append("text")
    .attr("class", "vis-title")
    .attr("x", (BEFORE_VAL_X + AFTER_VAL_X) / 2.0)
    .attr("y", 0.88 * SVG_BOX.height)
    .style("alignment-baseline", "middle")
    .text("Total Medal Counts per Games by Country");

// Background
d3.xml("olympic-games.svg").mimeType("image/svg+xml").get(function (xml) {
    d3.select(d3.select("div#vis").node().appendChild(xml.documentElement))
        .attr("class", "background")
        .attr("width", SVG_BOX.width)
        .attr("x", 400);

})

let timeline = svg.append("g")
    .attr("class", "timeline")
    .attr("transform", "translate(" + SVG_BOX.left + "," + SVG_BOX.top + ")");

let countryCodes = {};
let countryNames = {};
let selectedCountries = {};
let numActiveSelections = 0;
d3.csv("country_codes.csv", function (data) {
    for (let i = 0; i < data.length; ++i) {
        countryCodes[data[i].Country] = data[i].Code;
        countryNames[data[i].Code] = data[i].Country;
        selectedCountries[data[i].Code] = false;
    }
    var currentYear = { before: "1956", after: "2018" };
    d3.csv("medal_counts_by_year.csv", function (data) {
        let currentData = { before: {}, after: {} };
    
        data.map(function (d) {
            d.TiedWith = d.TiedWith.split("|");
            return d;
        });
    
        let lineData = genLineData(data);
    
        yScale.domain(d3.extent(data, function (d) { return +d.Total; }));
        timelineScale.domain(d3.extent(data, function (d) { return +d.Year; }));
    
        let years = lineData.keys().map(function (d) { return +d; }).sort();
        timelineSnap
            .domain(d3.pairs(years, function (a, b) {
                return (a + b) / 2.0;
            }))
            .range(years);
    
        timeline.append("line")
            .attr("class", "track")
            .attr("stroke-dasharray", "1.5, 4")
            .attr("y1", timelineScale.range()[0])
            .attr("y2", timelineScale.range()[1])
    
        let timelineLabel = timeline.insert("g", ".track-overlay")
            .attr("class", "ticks")
            .selectAll(".timeline-label")
            .data(years);
    
        timelineLabel.enter().append("g")
            .attr("class", "timeline-label")
            .attr("transform", function (d) {
                return "translate(0," + timelineScale(d) + ")";
            })
            .append("text")
            .attr("text-anchor", "middle")
            .style("alignment-baseline", "middle")
            .text(function (d) { return d; });
    
        var handleBefore = timeline.append("circle")
            .attr("class", "handle")
            .attr("r", 8)
            .attr("cx", -20)
            .attr("cy", timelineScale(currentYear.before))
            .call(d3.drag()
                .on("drag", function () {
                    let year = timelineSnap(timelineScale.invert(d3.event.y));
                    handleBefore.attr("cy", timelineScale(year));
                    if (year != +currentYear.before) {
                        currentYear.before = "" + year;
                        currentData.before = data.filter(function (d) {
                            return d.Year == currentYear.before;
                        });
                        update(currentData.before, false);
                        drawLines(currentData.before, currentData.after);
                    }
                }));
    
        var handleAfter = timeline.append("circle")
            .attr("class", "handle")
            .attr("r", 8)
            .attr("cx", 20)
            .attr("cy", timelineScale(currentYear.after))
            .call(d3.drag()
                // .on("start.interrupt", function () { timeline.interrupt(); })
                .on("drag", function () {
                    let year = timelineSnap(timelineScale.invert(d3.event.y));
                    handleAfter.attr("cy", timelineScale(year));
                    if (year != +currentYear.after) {
                        currentYear.after = "" + year;
                        currentData.after = data.filter(function (d) {
                            return d.Year == currentYear.after;
                        });
                        update(currentData.after, true);
                        drawLines(currentData.before, currentData.after);
                    }
                }));
    
        currentData.before = data.filter(function (d) { return d.Year == currentYear.before; });
        currentData.after = data.filter(function (d) { return d.Year == currentYear.after; });
        update(currentData.before, false);
        update(currentData.after, true);
        drawLines(currentData.before, currentData.after);
    });
    
    function genLineData(data) {
        // Map of year -> map of country -> medal counts
        let map = d3.map();
        for (let i = 0; i < data.length; ++i) {
            let d = data[i];
            if (map.get(d.Year) == undefined) {
                map.set(d.Year, {});
            }
            map.get(d.Year)[d.Country] = {
                "Gold": +d.Gold,
                "Silver": +d.Silver,
                "Bronze": +d.Bronze,
                "Total": +d.Total
            }
        }
        return map;
    }
    
    function drawLines(before, after) {
        svg.selectAll(".slopegraph-line").remove();
    
        let drawableSet = before.filter(function (d) {
            return after.find(function (dAfter) {
                return d.Country == dAfter.Country
                    || countryCodes[d.Country] == countryCodes[dAfter.Country];
            })
        });
    
        excluded = [];
    
        excluded.push(before.filter(function (d) {
            return drawableSet.findIndex(function (drawable) {
                return d.Country == drawable.Country;
            }) < 0;
        }));
    
        excluded.push(after.filter(function (d) {
            return drawableSet.findIndex(function (drawable) {
                return d.Country == drawable.Country;
            }) < 0;
        }));
    
        for (let i = 0; i < excluded.length; ++i) {
            for (let j = 0; j < excluded[i].length; ++j) {
                let sideClass = excluded[i][j].Year == before[0].Year ? ".before" : ".after";
                let countryClass = "." + countryCodes[excluded[i][j].Country];
                d3.select(sideClass + " " + countryClass).classed("excluded", true);
            }
        }
    
        for (let i = 0; i < drawableSet.length; ++i) {
            let countryCode = countryCodes[drawableSet[i].Country];
            let countryClass = "." + countryCode;
            let y1 = +d3.select(".before" + " " + countryClass).attr("y");
            let y2 = +d3.select(".after" + " " + countryClass).attr("y");
            let increased = y1 < y2;
            let graphLine = svg.append("line")
                .attr("class", "slopegraph-line " + countryCode)
                .classed("selected", selectedCountries[countryCode])
                .classed("unselected", !selectedCountries[countryCode])
                .classed("increase", increased)
                .classed("decrease", !increased)
                .attr("x1", LINE_X1).attr("y1", y1)
                .attr("x2", LINE_X2).attr("y2", y2)
                .style("stroke-opacity", ZERO_OPACITY)
                .transition(t)
                .style("stroke-opacity", 1);
        }
    
        updateLineColors();
    }
    
    function updateLineColors() {
        if (numActiveSelections > 0) {
            // Mute colors and unbold unselected lines
            d3.selectAll(".slopegraph-line.unselected")
                .style("stroke", function () {
                    let currLine = d3.select(this);
                    return d3.interpolate(currLine.style("stroke"), "lightgray")(0.75);
                })
                .style("stroke-width", null);
    
            // If we selected a line, disable custom styling so it defaults to CSS
            // Make selected lines bolder
            d3.selectAll(".slopegraph-line.selected")
                .style("stroke", null)
                .style("stroke-width", 2);
        }
        else {
            // No active selection -> use defulats
            d3.selectAll(".slopegraph-line")
                .style("stroke", null)
                .style("stroke-width", null);
        }
    }
    
    function update(data, after) {
        let valX = BEFORE_VAL_X;
        let labelX = BEFORE_LABEL_X;
        let sideClass = "before";
        let textAnchor = "end";
    
        if (after == true) {
            valX = AFTER_VAL_X;
            labelX = AFTER_LABEL_X;
            sideClass = "after";
            textAnchor = "start";
        }
    
        svg.selectAll("." + sideClass).remove();
    
        let update = svg.selectAll("." + sideClass)
            .data(data);
    
        let enter = update.enter().append("g")
            .attr("class", sideClass)
            .each(function (d) {
                let tiedCountriesGroup = d3.select(this);
                let x = labelX;
                for (let i = 0; i < d.TiedWith.length; ++i) {
                    if (d.Country != d.TiedWith[0]) {
                        break;
                    }
                    let countryCode = countryCodes[d.TiedWith[i]];
                    let currCountry = tiedCountriesGroup.append("text")
                        .attr("class", countryCode)
                        .classed("selected", selectedCountries[countryCode])
                        .classed("unselected", !selectedCountries[countryCode])
                        .attr("country", countryCode)
                        .attr("x", x)
                        .attr("y", function (d) { return yScale(d.Total); })
                        .style("alignment-baseline", "middle")
                        .style("text-anchor", textAnchor)
                        .style("fill-opacity", ZERO_OPACITY)
                        .text(countryCode + ",")
                        .on("mouseover", displayTooltip)
                        .on("mouseout", removeTooltip)
                        .on("contextmenu", displayContextMenu)
                        .transition(t)
                        .style("fill-opacity", 1);
                    let textBox = currCountry.node().getBBox();
                    if (after == true) {
                        x = textBox.x + textBox.width + SPACE_WIDTH;
                    }
                    else {
                        x = textBox.x - SPACE_WIDTH;
                    }
                }
            });
    
        enter.append("text")
            .attr("class", "value")
            .attr("x", valX)
            .attr("y", function (d) { return yScale(d.Total); })
            .style("alignment-baseline", "middle")
            .style("text-anchor", textAnchor)
            .style("fill-opacity", ZERO_OPACITY)
            .text(function (d) { return d.Total; })
            .transition(t)
            .style("fill-opacity", 1);
    
        // Axis title (year)
        svg.append("text")
            .attr("class", sideClass + " axis-title")
            .attr("x", labelX)
            .attr("y", yScale.range()[0] + AXIS_LABEL_OFFSET)
            .style("alignment-baseline", "middle")
            .style("text-anchor", "middle")
            .style("font-size", 20)
            .text(data[0].Year);
    
        // Highlight timeline
        // let currentYear = data[0].Year;
        d3.selectAll(".timeline-label")
            .style("fill", function (d) {
                if (d == currentYear.before || d == currentYear.after) {
                    return "orange";
                }
                return null;
            });
    }
    
    function displayTooltip() {
        let countryCode = d3.select(this).text().slice(0, -1);
        let country = this.getBBox();
        let tooltip = d3.select(this.parentNode).append("g")
            .attr("class", "tooltip")
            .attr("transform", function () {
                let x = country.x + country.width / 2.0;
                let y = country.y - 15;
                return "translate(" + x + "," + y + ")";
            });
        let tooltipLabel = tooltip.append("text")
            .text(countryNames[countryCode]);
        let tooltipBox = tooltipLabel.node().getBBox();
        tooltip.insert("rect", "text")
            .attr("rx", 3).attr("ry", 3)
            .attr("x", tooltipBox.x - TOOLTIP_MARGIN / 2).attr("y", tooltipBox.y - TOOLTIP_MARGIN / 2)
            .attr("width", tooltipBox.width + TOOLTIP_MARGIN)
            .attr("height", tooltipBox.height + TOOLTIP_MARGIN)
            .style("alignment-baseline", "middle");
    }
    
    function removeTooltip() {
        d3.select(this.parentNode).select(".tooltip").remove();
    }
    
    function displayContextMenu() {
        d3.event.preventDefault();
        let menuX = d3.mouse(this)[0] + 7;
        let menuY = d3.mouse(this)[1] + 7;
    
        d3.select('.context-menu').remove();
    
        let country = d3.select(this).attr("country");
    
        let menu = svg.append("g")
            .attr("class", "context-menu")
            .attr("transform", "translate(" + menuX + "," + menuY + ")")
            .on("click", function () {
                selectedCountries[country] = !selectedCountries[country];
                d3.select(".slopegraph-line." + country)
                    .classed("selected", selectedCountries[country])
                    .classed("unselected", !selectedCountries[country]);
                if (selectedCountries[country] == true) {
                    ++numActiveSelections;
                }
                else {
                    --numActiveSelections;
                    // In case its negative
                    numActiveSelections = Math.max(numActiveSelections, 0);
                }
    
                updateLineColors();
    
                d3.select(".before ." + country)
                    .classed("selected", selectedCountries[country])
                    .classed("unselected", !selectedCountries[country]);
                d3.select(".after ." + country)
                    .classed("selected", selectedCountries[country])
                    .classed("unselected", !selectedCountries[country]);
            })
    
        let menuText = menu.append("text")
            .attr("x", POPUP_OFFSET).attr("y", POPUP_OFFSET)
            .style("alignment-baseline", "hanging")
            .text(selectedCountries[country] == true ? "Unselect" : "Select");
    
        let textBox = menuText.node().getBBox();
        menu.insert("rect", "text")
            .attr("width", textBox.width + POPUP_OFFSET * 2)
            .attr("height", textBox.height + POPUP_OFFSET * 2);
    
        d3.select('svg')
            .on('click', function () { d3.select('.context-menu').remove(); });
    }
});

