function RtMul = mulRt(RtLeft, RtRight)

RtMul = [RtLeft(:,1:3)*RtRight(:,1:3) RtLeft(:,1:3)*RtRight(:,4)+ RtLeft(:,4)];