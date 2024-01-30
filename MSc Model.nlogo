extensions [nw]
turtles-own
[
  beta               ;constant - decide biased or not ; 1- more likely to express; 1+ less likely to express
  gamma                ;constant - decide skewness
  delta            ;constant -
  learning-rate       ;same with society  (-1, 1)
  opinion             ;inner thought of agents
  valence             ;expressed opinion of agents if they choose to express it (opinion = valence) if not (valence =0)
  speak               ;express decision (1: speak, 0:silent)
  agree-neighbor      ;# of agreeing neigbors
  disagree-neighbor   ;# of disagreeing neigbors
  reward              ;total confirmation reward; sum of attitudes of neighbours
  Q-Value             ;reinforcement learning value
  new-Q-Value         ;to update Q-value
  expression-chance   ;chance of expressing their opinions
  new-expression-chance ;
  initial-neighbors
  ;output related attributes
  ratio1
  ratio2
  echo-ratio1
  echo-ratio2
  paradox-ratio
  paradox-ratio2
  current-neighbors

  discrepancy-percentage-min
  discrepancy-percentage-maj]

links-own
[conflict
 expressive-ends
 cut
 cutting-prob
 cut-mean
 cut-sd]

globals
[ my-seed
  re-linking      ;re-linking rule
  network-type-decision  ;network-building-rule
  ;output related globals
  minority-ratio
  majority-ratio
  echo-ratio
  echo-const
  perceived-min-for-min
  perceived-min-for-maj
  unexpressive-percentage
  unexpressive-minority
  unexpressive-majority
  sd-for-maj
  sd-for-min
  friendship-paradox]

to setup
  clear-all
  set my-seed new-seed
  random-seed my-seed
  setup-nodes
  setup-network
  setup-link-neighbors
  reset-ticks
end


to setup-nodes
  create-turtles number-of-people
  [
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set Q-Value 0       ;for giving expression chance 50%
    set learning-rate av   ;society decision
    set beta  bv          ;
    set gamma gv        ;
    set delta dv            ;
    set shape "circle"
    set opinion -1
  ]
  ask n-of (count turtles * minority-percentage)   turtles [set opinion 1 ]
 ; initially-all-expressive ;initially expressive for certain
   setup-expression         ;initially expressive with probability
   assign-node-color        ;initial node colors
end

to setup-network
 setup-spatially-clustered-network
end

to setup-link-neighbors
  assign-link-label
  assign-link-color
  assign-link-cutting-prob
  count-neighbors
  ask turtles [set initial-neighbors count link-neighbors]  ;number of agents with link-neighbor < 3 initially and finally
  ask links [set cut-mean 0.5
             set cut-sd 0.12]
  set echo-const 0.50

end

to setup-spatially-clustered-network
  let num-links (average-node-degree * number-of-people) / 2
  while [count links < num-links ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [ create-link-with choice ]
    ]
  ]
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-people)) 1
  ]
end

to initially-all-expressive
  ask turtles [set valence opinion
 set speak 1]
end

to setup-expression
  ask turtles [
    set expression-chance (beta / ( gamma + ( e ^ ( - delta * Q-Value)))) ]
  ask turtles [
    ifelse random-float 1 <= expression-chance
  [set speak 1
   set valence opinion]
  [set speak 0
      set valence 0] ]
end

to assign-node-color
  ask turtles with [valence = -1]
  [set color red]
  ask turtles with [valence = 1]
  [set color blue]
  ask turtles with [speak = 0 and opinion = -1]
  [set color red + 2]
  ask turtles with [speak = 0 and opinion = 1]
  [set color blue + 2]

end

to assign-link-label
  ask links with [ [opinion] of end1 * [opinion] of end2 = -1 ] [set conflict 1]
  ask links with [ [opinion] of end1 * [opinion] of end2 = 1 ] [set conflict 0]
  ask links with [ [speak] of  end1 + [speak] of  end2 = 2 ] [set expressive-ends 2]
  ask links with [ [speak] of  end1 + [speak] of  end2 = 1 ] [set expressive-ends 1]
  ask links with [ [speak] of  end1 + [speak] of  end2 = 0 ] [set expressive-ends 0]
end

to assign-link-color
  ask links with [ conflict = 0 and expressive-ends = 2] [set color green]      ;agreeing neihgbors
  ask links with   [conflict = 1 and expressive-ends = 2] [set color red]       ;disagreeing neihgbors
  ask links with  [ expressive-ends = 1 or expressive-ends = 0 ] [set color white]      ;silent neighbors
end

to assign-link-cutting-prob
  ask links [
    set cutting-prob random-normal 0.5 0.12
  ]
end

to count-neighbors
  ask turtles with [opinion = 1 ]
  [set agree-neighbor count link-neighbors with [valence = 1]
   set disagree-neighbor count link-neighbors with [valence = -1]]
   ask turtles with [opinion = -1 ]
  [set agree-neighbor count link-neighbors with [valence = -1]
   set disagree-neighbor count link-neighbors with [valence = 1]]
  ask turtles [set current-neighbors count link-neighbors ]

end

to go
  link-isolated-agents
  calculate-reward
  update-Q-Value
  calculate-expression-chance
  decide-expression
  update-expression-chance
  assign-node-color
  assign-link-label
  assign-link-color
  count-neighbors
  outputs
  tick
end




to link-isolated-agents
  ask turtles with [current-neighbors = 0]
   [ create-link-with one-of other turtles
    [set cutting-prob random-normal 0.5 0.12]]
  count-neighbors
end


to calculate-reward
  ask turtles
  [
 ifelse agree-neighbor + disagree-neighbor > 0         ;silent nodes not affect others
  [set reward ((agree-neighbor - disagree-neighbor) / (agree-neighbor + disagree-neighbor))  ]
    [set reward 0] ]
end

to update-Q-Value
  ask turtles[
  set new-Q-Value  ((1 - learning-rate) * Q-Value + (learning-rate * reward))
    set Q-Value new-Q-Value ]
end

to calculate-expression-chance
  ask turtles[
    set new-expression-chance (beta / ( gamma + ( e ^ ( - delta * Q-Value)))) ]
  ask turtles with [ new-expression-chance > 1]
  [set new-expression-chance 1]
end

to decide-expression
     ask turtles
  [ if (speak = 0 and new-expression-chance > expression-chance) or (speak = 1 and new-expression-chance < expression-chance)
    [ express-decision] ]
end

to express-decision
  ifelse random-float 1 <= new-expression-chance
  [set speak 1
   set valence opinion]
  [set speak 0
   set valence 0]
end

to update-expression-chance
  ask turtles
  [set expression-chance new-expression-chance]
end

;;HOMOPHILY



;; OUTPUTS

to outputs
  calculate-minority-illusion
  calculate-majority-illusion
  calculate-friendship-paradox
  calculate-echo-chamber-density
  calculate-perceived-perc-for-min
  calculate-perceived-perc-for-maj
  set minority-ratio ( count turtles with [ratio1 > minority-percentage ] / (number-of-people * (1 - minority-percentage)))
  set majority-ratio  ( count turtles with [ratio2 > minority-percentage ] / (number-of-people * minority-percentage))
  set friendship-paradox count turtles with [paradox-ratio > 0.5] / number-of-people
  set echo-ratio (count turtles with [echo-ratio2 > echo-const]) / (count turtles)
  set unexpressive-percentage ((count turtles with [speak = 0]) / number-of-people )
  set unexpressive-minority ((count turtles with [color = blue + 2]) / ( count turtles with [opinion = 1]))
  set unexpressive-majority ((count turtles with [color = red + 2]) / ( count turtles with [opinion = -1]))
  set sd-for-min  sum [discrepancy-percentage-min] of turtles / (minority-percentage * number-of-people)
  set sd-for-maj  sum [discrepancy-percentage-min] of turtles / ((1 - minority-percentage) * number-of-people)
end

to calculate-perceived-perc-for-min
  ask turtles with [opinion = 1 and count link-neighbors > 0]
  [let percevied-for-min count link-neighbors with [color = blue] / count link-neighbors
    set discrepancy-percentage-min (minority-percentage - percevied-for-min ) ^ 2 ]
end


to calculate-perceived-perc-for-maj
    ask turtles with [opinion = -1 and count link-neighbors > 0]
  [let percevied-for-maj count link-neighbors with [color = blue] / count link-neighbors
    set discrepancy-percentage-maj (minority-percentage - percevied-for-maj) ^ 2 ]
end

to calculate-minority-illusion
    ask turtles [set ratio1 0
  set minority-ratio  0]
ask turtles with [opinion = -1 ]
  [if count link-neighbors > 0
    [set ratio1 count link-neighbors with [color = blue ]  / count link-neighbors ] ]
end

to calculate-majority-illusion
    ask turtles [set ratio2 0
  set majority-ratio  0]
ask turtles with [opinion = 1 ]
  [if count link-neighbors > 0
    [set ratio2 count link-neighbors with [color = blue ]  / count link-neighbors ] ]
end

to calculate-friendship-paradox
   ask turtles [set paradox-ratio 0]
  ask turtles
  [let a count link-neighbors
   set paradox-ratio count link-neighbors with [ count link-neighbors > a]]
end


to calculate-echo-chamber-density
  ask turtles [set echo-ratio1 0]
  ask turtles with [speak = 1]
  [set echo-ratio1 count my-links with [conflict = 0 and expressive-ends = 2]]
  ask turtles with [count link-neighbors  > 0 and echo-ratio1 > 0]
  [set echo-ratio2 echo-ratio1 / (count link-neighbors) ]
end
@#$#@#$#@
GRAPHICS-WINDOW
530
12
1649
582
-1
-1
11.0
1
10
1
1
1
0
0
0
1
-50
50
-25
25
1
1
1
ticks
30.0

BUTTON
20
212
115
252
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
130
212
225
252
NIL
go 
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
24
84
229
117
number-of-people
number-of-people
500
1000
1000.0
500
1
NIL
HORIZONTAL

SLIDER
25
160
230
193
average-node-degree
average-node-degree
4
8
6.0
2
1
NIL
HORIZONTAL

MONITOR
23
269
105
314
Silent Blues
count turtles with [opinion = 1 and valence = 0 ]
17
1
11

PLOT
0
634
832
1053
Sileny Percentage
tick
agents
0.0
500.0
0.0
1.0
false
false
"" ""
PENS
"Minority" 1.0 0 -14730904 true "" "plot count turtles with [color = blue + 2] /  count turtles with [opinion = 1]"
"Majority" 1.0 0 -8053223 true "" "plot count turtles with [color = red + 2] /  count turtles with [opinion = -1]"

SLIDER
25
125
206
158
minority-percentage
minority-percentage
0.1
0.5
0.2
0.1
1
NIL
HORIZONTAL

MONITOR
14
418
214
463
Red Links
count links with [ color = red ]
17
1
11

MONITOR
14
367
225
412
Number of Links
count links
17
1
11

MONITOR
18
318
177
363
NIL
my-seed
17
1
11

MONITOR
108
269
188
314
Silent Reds
count turtles with [color = red \n+ 2]
17
1
11

PLOT
910
619
1730
1053
maj minor
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"minority illusion" 1.0 0 -16777216 true "plot (minority-ratio)" "plot (minority-ratio)"
"echo chamber" 1.0 0 -5298144 true "plot (echo-ratio)" "plot (echo-ratio)"
"unexpressive-percentage" 1.0 0 -13840069 true "" "plot (friendship-paradox)"

MONITOR
12
469
209
514
Links Labeled Cut
count links with [cut = \"yes\"]
17
1
11

MONITOR
15
564
255
609
NIL
min [count link-neighbors] of turtles
17
1
11

MONITOR
16
517
260
562
NIL
max [count link-neighbors] of turtles
17
1
11

MONITOR
348
348
430
393
NIL
sd-for-maj
17
1
11

MONITOR
348
400
431
445
NIL
sd-for-min
17
1
11

INPUTBOX
318
32
467
92
av
0.1
1
0
Number

INPUTBOX
313
101
462
161
bv
2.0
1
0
Number

INPUTBOX
320
177
469
237
gv
1.0
1
0
Number

INPUTBOX
321
253
470
313
dv
5.0
1
0
Number

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment 1 - static" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>friendship-paradox</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2 - rules degree final values" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>friendship-paradox</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily-degree">
      <value value="0.5"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="re-linking-choice">
      <value value="&quot;unbiased&quot;"/>
      <value value="&quot;geo-biased&quot;"/>
      <value value="&quot;opinion-biased&quot;"/>
      <value value="&quot;geo-opinion-biased&quot;"/>
      <value value="&quot;2nd-degree&quot;"/>
      <value value="&quot;biased-2nd-degree&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 3 - selected parameters homophily" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 1 - randomly dynamic" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>friendship-paradox</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2 - with time -selected degree" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>sd-for-maj</metric>
    <metric>sd-for-min</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily-degree">
      <value value="0.5"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="re-linking-choice">
      <value value="&quot;unbiased&quot;"/>
      <value value="&quot;geo-biased&quot;"/>
      <value value="&quot;opinion-biased&quot;"/>
      <value value="&quot;geo-opinion-biased&quot;"/>
      <value value="&quot;2nd-degree&quot;"/>
      <value value="&quot;biased-2nd-degree&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 1 - static" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>friendship-paradox</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 1 - static2" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>my-seed</metric>
    <metric>unexpressive-minority</metric>
    <metric>unexpressive-majority</metric>
    <metric>echo-ratio</metric>
    <metric>minority-ratio</metric>
    <metric>friendship-paradox</metric>
    <enumeratedValueSet variable="minority-percentage">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="100"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutting-percentage">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
