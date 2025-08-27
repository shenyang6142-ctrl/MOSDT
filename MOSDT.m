%云服务器加边缘服务器
[mt,failrate,c] = mian(40,600); 
function [mt,failrate,c] = mian(m,n)
    for i = m : 40 : n
        M=createM(20);
        B=createB(i);          
        cloud=createCloud(1);
        M1=M;
        M2=M;
        B1=B;
        B2=B;
        cloud1=cloud;
        cloud2=cloud;
        B=resort(B);
        [B,M,cloud]=Algorithm1(B,M,cloud);
        [mt((i-m)/40+1),failrate((i-m)/40+1),c((i-m)/40+1),cloud] = result(B,M,cloud);
    end
    x=m:40:n;
    x=x/10;
    figure(1)
    plot(x,mt,'-^','color','b','LineWidth', 2);
    xlabel("Lambda","FontSize",15, 'FontName', 'SimHei');
    ylabel("Average task migration numbers","FontSize",15, 'FontName', 'SimHei');
    legend('MOSDT', 'FontName', 'SimHei','box','off'); % 添加图例，区分两条曲线
    grid on
    hold off
    figure(2);
    plot(x,failrate,'-^','color','b','LineWidth', 2);
    xlabel("Lambda","FontSize",15, 'FontName', 'SimHei');
    ylabel("Failure rate","FontSize",15, 'FontName', 'SimHei');
    legend('MOSDT', 'FontName', 'SimHei','box','off'); % 添加图例，区分两条曲线
    grid on
    ylim([0,1]);
    hold off
    figure(3)
    plot(x,c,'-^','color','b','LineWidth', 2);
    xlabel("Lambda","FontSize",15, 'FontName', 'SimHei');
    ylabel("Average scheduling costs","FontSize",15, 'FontName', 'SimHei');
    legend('MOSDT', 'FontName', 'SimHei','box','off'); % 添加图例，区分两条曲线
    grid on
    hold off
end

function [mt,failrate,c,cloud] = result(B,M,cloud)
    c=0;
    fail=0;
    w=0;
    for i = 1:size(B,2)
        if B(i).nodes(size(B(i).nodes,1)).ft == 0
            fail=fail+1;
        end
        failrate = fail/size(B,2);
    end
    mt=0;
    for i = 1:size(B,2)
        if B(i).nodes(size(B(i).nodes,1)).ft ~= 0
            for j = 1:size(B(i).edges,1)
                pre = B(i).nodes(B(i).edges(j).pre+1).where ; 
                suc = B(i).nodes(B(i).edges(j).suc+1).where;
                if pre == 0 || suc == 0   %%两个至少一个再车辆上
                    if pre ~= suc         %%一个边缘服务器，一个车辆
                        if suc == 0       
                            temp=pre;
                            pre=suc;
                            suc=temp;
                        end
                        if suc == size(M,2)+1  %%车与云服务武器
                            mt = mt + 2;
                        else                   %%车与边缘服务器
                            if abs(findcarpos(B,i,B(i).nodes(pre+1).ft) - M(suc).pos)>100    %%边缘服务器不在车辆范围内
                                mt=mt+2;
                            elseif abs(findcarpos(B,i,B(i).nodes(pre+1).ft) - M(suc).pos)<=100  %%在范围内
                                mt=mt+1;
                            end
                        end
                    end
                end
                if pre ~= 0 && suc ~= 0 && pre ~= suc  %%边缘服务器与边缘服务器以及云服务器
                    mt=mt+1;
                end
            end
        end
    end
    mt=mt/(size(B,2)-fail);
    for i = 1:size(B,2)
        if B(i).nodes(size(B(1).nodes,1)).ft ~= 0
            for j = 1:size(B(i).nodes,1)-1
                w=w+B(i).nodes(j).comp;
                c=c+transenergy(i,j,B,M) + scheduleenergy(i,j,B,M,cloud);
            end
        end
    end
    c=c/w*5000;
end

function x = scheduleenergy(i,j,B,M,cloud)
    if B(i).nodes(j+1).where == 0
        x=B(i).nodes(j+1).comp / B(i).f * B(i).c;
    elseif B(i).nodes(j+1).where == size(M,2)+1
        x=B(i).nodes(j+1).comp / cloud.f * cloud.c;
    else
        x=B(i).nodes(j+1).comp / M(B(i).nodes(j+1).where).f * M(B(i).nodes(j+1).where).c;
    end
end

function x=transenergy(i,j,B,M)
    x=0;
    if j == 0
        x=x+0;
    else
        pre = findpre(B,i,j);
        for n = pre
            index=[B(i).edges.pre] == n & [B(i).edges.suc] == j;
            if B(i).nodes(n+1).where == B(i).nodes(j+1).where   %%在同一个边缘服务器或者车辆
                x=x+0;
            end
            if (B(i).nodes(n+1).where == 0 || B(i).nodes(j+1).where == 0) && B(i).nodes(n+1).where ~= B(i).nodes(j+1).where %%有一个在车辆，一个边缘服务器
                if B(i).nodes(n+1).where == 0
                    if B(i).nodes(j+1).where == size(M,2)+1 %%车到云服务器
                        x = x + B(i).edges(index).trans * (3 * 7.81 * 10^-9 + 10 * 80 * 10^-9);
                    else         %%车到边缘服务器
                        if abs(findcarpos(B,i,B(i).nodes(n+1).ft) - M(B(i).nodes(j+1).where).pos) > 100
                            x=x+B(i).edges(index).trans * (5 *17.77*10^-9 +3 * 7.81 * 10^-9);
                        else
                            x=x+B(i).edges(index).trans * 3 * 7.81 * 10^-9;
                        end
                    end
                else
                    if B(i).nodes(n+1).where == size(M,2)+1 %%车到云服务器
                        x = x + B(i).edges(index).trans * (3 * 7.81 * 10^-9 + 10 * 80 * 10^-9);
                    else
                        if abs(findcarpos(B,i,B(i).nodes(n+1).ft) - M(B(i).nodes(n+1).where).pos) > 100
                            x=x+B(i).edges(index).trans * (5 *17.77*10^-9 +3 * 7.81 * 10^-9);
                        else
                            x=x+B(i).edges(index).trans * 5 *17.77*10^-9;
                        end
                    end
                end
            end
            if B(i).nodes(n+1).where ~= 0 && B(i).nodes(j+1).where ~= 0 && B(i).nodes(n+1).where ~= B(i).nodes(j+1).where %%边缘服务器对边缘服务器或者云服务器
                if B(i).nodes(n+1).where == size(M,2)+1 || B(i).nodes(j+1).where == size(M,2)+1  %%边缘服务器对云服务器
                    x=x+B(i).edges(index).trans * 10 * 80 * 10^-9;
                else        %%边缘服务器对边缘服务器
                    x=x+B(i).edges(index).trans * 5 * 17.77 * 10^-9;
                end
            end
        end
    end
end

function [B,M,cloud]=Algorithm1(B,M,cloud)
    [x,Border]=sort([B.r]);     %获得应用程序调度顺序
    for i = Border   %遍历应用程序
        B1=B;
        M1=M;
        [x,norder]=sort([B(1).nodes.rank],"descend");
        for j = norder-1
            [B,M,cloud]=Algorithm2(B,M,i,j,cloud);
            if B(i).nodes(j+1).where == -1
                B=B1;
                M=M1;
                break;
            end
        end
    end
end

function [B,M,cloud]=Algorithm2(B,M,i,j,cloud)   %%调度第i个应用程序第j个任务
    B1=B;
    M1=M;
    if j==size(B(i).nodes,1)-1     %%对于虚拟任务终止任务，调度在车上
        B(i).nodes(j+1).st=B(i).req;
        B(i).nodes(j+1).ft=B(i).req;
        B(i).nodes(j+1).statue=1;
        B(i).nodes(j+1).where=0;
        B(i).schedulelist=[i,j;B(i).schedulelist];
    elseif j==0                    %%对于虚拟人任务起始任务，调度在车上
        st=inf;
        x=findcarpos(B,i,subdeadline(B,i,j));  %%车辆所在位置
        suc=findsuc(B,i,j);
        for n = suc
            trans = B(i).edges([B(i).edges.pre] == j & [B(i).edges.suc] == n).trans;
            t = B(i).nodes(n+1).st - transtime(0,B(i).nodes(n+1).where,trans,x,M);
            if t < st
                st=t;
            end
        end
        B(i).nodes(j+1).st=st;
        B(i).nodes(j+1).ft=st;
        B(i).nodes(j+1).statue=1;
        B(i).nodes(j+1).where=0;
        B(i).schedulelist=[i,j;B(i).schedulelist];
    else                           %%对于真实任务
        st = -inf;
        t=subdeadline(B,i,j);      %%估计子截止时间
        x=findcarpos(B,i,t);       %%找到车辆位置
        suc=findsuc(B,i,j);
        if suc==size(B(i).nodes,1)-1  %%后继任务是虚拟任务   
            E1=[];
        else
            E1=unique(findsucpos(B,i,j));  %%后继任务是真实需要调度的任务
        end
        E2 = setdiff(findedgecar(M,x),E1);
        E3 = setdiff(setdiff(0:size(M,2),E2),E1);
        if ~isempty(E1)
            [st,B,M,cloud]=Algorithm3(i,j,E1,st,B,M,cloud);
        end
        if st == -inf
            if ~isempty(E2)
                [st,B,M,cloud]=Algorithm3(i,j,E2,st,B,M,cloud);
            end
            if st == -inf
                if ~isempty(E3)
                    [st,B,M,cloud]=Algorithm3(i,j,E3,st,B,M,cloud);
                end
                if st == -inf
                    [st,B,M,cloud]=Algorithm3(i,j,size(M,2)+1,st,B,M,cloud);
                end
            end
        end
    end
end

function [st,B,M,cloud]=Algorithm3(i,j,E,st,B,M,cloud)
    st = -inf;     %%调度失败返回-inf
    ft = -inf;
    pos=-1;
    tasknum=0;
    for n=1:size(E,2)
        [st1,ft1,num,cloud]=schedule(i,j,E(n),B,M,cloud);
        if st1 == -inf
            [st1,ft1,num,B,M,cloud] = Algorithm4(i,j,E(n),st1,ft1,num,B,M,cloud);
        end
        if st1>st
            st=st1;
            ft=ft1;
            pos=E(n);
            tasknum=num;
        end
    end
    if pos == 0 
        B(i).nodes(j+1).st=st;
        B(i).nodes(j+1).ft=ft;
        B(i).nodes(j+1).statue=1;
        B(i).nodes(j+1).where=pos;
        B(i).schedulelist=[B(i).schedulelist(1:tasknum,:);i,j;B(i).schedulelist(tasknum+1:end,:)];
    elseif pos > 0 && pos < size(M,2)+1
        B(i).nodes(j+1).st=st;
        B(i).nodes(j+1).ft=ft;
        B(i).nodes(j+1).statue=1;
        B(i).nodes(j+1).where=pos;
        M(pos).schedulelist=[M(pos).schedulelist(1:tasknum,:);i,j;M(pos).schedulelist(tasknum+1:end,:)];
    elseif pos == size(M,2)+1
        if st >= B(i).r && ft <= B(i).req
            B(i).nodes(j+1).st=st;
            B(i).nodes(j+1).ft=ft;
            B(i).nodes(j+1).statue=1;
            B(i).nodes(j+1).where=pos;
            cloud.schedulelist=[cloud.schedulelist;i,j];
        end
    end
end

function [st,ft,num,cloud]=schedule(i,j,Ea,B,M,cloud)
    if Ea ~= size(M,2)+1
        num=-1;
        st = -inf;
        ft = -inf;
        deadline = deadlineforM(i,j,Ea,B,M);
        if Ea == 0 
            list = B(i).schedulelist;
            scheduletime = B(i).nodes(j+1).comp / B(i).f;
        else
            list = M(Ea).schedulelist;
            scheduletime = B(i).nodes(j+1).comp / M(Ea).f;
        end
        timelist=[0,0];
        for m=1:size(list,1)
            timelist = [timelist;B(list(m,1)).nodes(list(m,2)+1).st,B(list(m,1)).nodes(list(m,2)+1).ft];
        end
        if size(timelist,1)>1
            for n = 2:size(timelist,1)
                if timelist(n,1) <= deadline
                    if timelist(n,1)-scheduletime >= timelist(n-1,2) && timelist(n,1)-scheduletime >= B(i).r
                        st = timelist(n,1)-scheduletime;
                        ft = st+scheduletime;
                        num=n-2;
                    end
                else
                    n=n-1;
                    break;
                end
            end
        else
            n=1;
        end
        if (deadline - scheduletime) >= timelist(n,2) && (deadline - scheduletime) >= B(i).r
            st = deadline-scheduletime;
            ft = deadline;
            num=n-1;
        end
    elseif Ea == size(M,2)+1
        st = inf;
        ft = inf;
        num = -1;
        for suc = findsuc(B,i,j)
            trans = B(i).edges([B(i).edges.pre] == j & [B(i).edges.suc] == suc).trans;
            st1 = round(B(i).nodes(suc+1).st - transtime(B(i).nodes(suc+1).where,Ea,trans,findcarpos(B,i,subdeadline(B,i,j)),M) - B(i).nodes(j+1).comp / cloud.f,3);
            ft1 = round(st1 + B(i).nodes(j+1).comp / cloud.f,3);
            if st > st1
                st=st1;
                ft=ft1;
            end
        end

    end
end

function [st,ft,num,B,M,cloud]=Algorithm4(i,j,Ea,st,ft,num,B,M,cloud)
    if Ea == size(M,2)+1
        return;
    end
    B1=B;
    M1=M;
    num1=num;
    deadline = deadlineforM(i,j,Ea,B,M);
    if Ea == 0 
        list = B(i).schedulelist;     %%正向调度表
        scheduletime = B(i).nodes(j+1).comp / B(i).f;
    else
        list = M(Ea).schedulelist;    %%正向调度表
        scheduletime = B(i).nodes(j+1).comp / M(Ea).f;
    end
    timelist=[0,0];
    for h=1:size(list,1)
        timelist = [timelist;B(list(h,1)).nodes(list(h,2)+1).st,B(list(h,1)).nodes(list(h,2)+1).ft]; %%正向时间表
    end
    for m = size(timelist,1):-1:2    %%m-1是当前任务的下标
        if timelist(m,2)<=deadline
            if timelist(m,2)-scheduletime>=timelist(m-1,2) && timelist(m,2)-scheduletime>=B(i).r
                st = timelist(m,2)-scheduletime;
                ft = timelist(m,2);
                if Ea == 0 
                    B(i).nodes(j+1).st=st;
                    B(i).nodes(j+1).ft=ft;
                    B(i).nodes(j+1).statue=1;
                    B(i).nodes(j+1).where=Ea;
                    B(i).schedulelist(m-1,1)=i;
                    B(i).schedulelist(m-1,2)=j;
                elseif Ea > 0
                    B(i).nodes(j+1).st=st;
                    B(i).nodes(j+1).ft=ft;
                    B(i).nodes(j+1).statue=1;
                    B(i).nodes(j+1).where=Ea;
                    M(Ea).schedulelist(m-1,1)=i;
                    M(Ea).schedulelist(m-1,2)=j;
                end
                [st1,ft1,num,cloud]=schedule(list(m-1,1),list(m-1,2),Ea,B,M,cloud);
                if st1 ~= -inf && ft1<ft
                    pre=findpre(B,list(m-1,1),list(m-1,2));
                    flag=1;
                    for n = pre
                        x=[B(list(m-1,1)).edges.pre] == n & [B(list(m-1,1)).edges.suc] == list(m-1,2);
                        if B(list(m-1,1)).nodes(list(m-1,2)+1).ft + transtime(B(list(m-1,1)).nodes(n+1).where,B(list(m-1,1)).nodes(list(m-1,2)+1).where,B(list(m-1,1)).edges(x).trans,findcarpos(B,list(m-1,1),subdeadline(B,list(m-1,1),list(m-1,2))),M) > st1
                            flag=0;
                        end
                    end
                    if flag==1
                        if Ea == 0 
                            B(list(m-1,1)).nodes(list(m-1,2)+1).st=st1;
                            B(list(m-1,1)).nodes(list(m-1,2)+1).ft=ft1;
                            B(list(m-1,1)).nodes(list(m-1,2)+1).statue=1;
                            B(list(m-1,1)).nodes(list(m-1,2)+1).where=Ea;
                            B(list(m-1,1)).schedulelist=[B(list(m-1,1)).schedulelist(1:num,:);list(m-1,1),list(m-1,2);B(list(m-1,1)).schedulelist(num+1:end,:)];
                        elseif Ea > 0
                            B(i).nodes(j+1).st=st1;
                            B(i).nodes(j+1).ft=ft1;
                            B(i).nodes(j+1).statue=1;
                            B(i).nodes(j+1).where=Ea;
                            M(Ea).schedulelist=[M(Ea).schedulelist(1:num,:);list(m-1,1),list(m-1,2);M(Ea).schedulelist(num+1:end,:)];
                        end
                    end
                end
            end
        end
    end
    if st == -inf
        B=B1;
        M=M1;
        st=-inf;
        ft=-inf;
        num=num1;
    else
        if st1 == -inf || ft1>=ft
            B=B1;
            M=M1;
            st=-inf;
            ft=-inf;
            num=num1;
        else
            if flag==0
                B=B1;
                M=M1;
                st=-inf;
                ft=-inf;
                num=num1;
            end
        end
    end
end

function t=deadlineforM(i,j,Ea,B,M)    %%任务在设备Ma上的截止时间
    suc=findsuc(B,i,j);
    t=inf;
    for m = suc
        if B(i).nodes(m+1).where ~= Ea
            n = [B(i).edges.pre] == j & [B(i).edges.suc] == m;
            x=round(B(i).nodes(m+1).st - transtime(B(i).nodes(m+1).where,Ea,B(i).edges(n).trans,findcarpos(B,i,subdeadline(B,i,j)),M),3);
        else
            x=round(B(i).nodes(m+1).st,3);
        end
        if t>x
            t=x;
        end
    end
end

function suc=findsuc(B,i,a)  %%找到第i个任务图中任务a的后继任务
    suc=[];
    for j = 1 : size(B(i).edges,1)
        if a == B(i).edges(j).pre
            suc = [suc,B(i).edges(j).suc];
        end
    end
end

function pre=findpre(B,i,a)  %%找到第i个任务图中任务a的后继任务
    pre=[];
    for j = 1 : size(B(i).edges,1)
        if a == B(i).edges(j).suc
            pre = [pre,B(i).edges(j).pre];
        end
    end
end

function rank=rerank(B,i,a)  %%对第i个任务图第a个任务计算等级
    if a == size(B(i).nodes,1) - 1
        rank = B(i).req;
    else
        suc = findsuc(B,i,a);
        rank = inf;
        for m = suc
            j=[B(i).edges.pre] == a & [B(i).edges.suc] == m;
            x=B(i).nodes(m+1).rank-B(i).nodes(m+1).comp/5000-B(i).edges(j).trans*17.77*10^-9;
            if rank > x
                rank = x;
            end
        end
    end
end

function t=subdeadline(B,i,j)    %%子截止日期
    suc=findsuc(B,i,j);
    t=inf;
    for m = suc
        n = [B(i).edges.pre] == j & [B(i).edges.suc] == m;
        x=round(B(i).nodes(m+1).st-B(i).edges(n).trans*17.77*10^-9,3);
        if t>x
            t=x;
        end
    end
end

function x=findcarpos(B,i,a)   %%找到第a秒时车辆的位置
    x=B(i).xlabel+(a-B(i).r)*B(i).v;
    if x<0
        x=0;
    end
    if x>1100
        x=1100;
    end
end

function x=findedgecar(M,a)  %%找到在位置a时可以通信时的边缘服务器以及车辆
    x=[0];
    for i = 1 : size(M,2)
        if abs(M(i).pos-a) <= 100
            x=[x,M(i).order];
        end
    end

end

function t = transtime(sa,sb,trans,x,M)    %%两个设备之间的传输时间
    if sa ~= sb && sa ~= 0 && sb ~= 0  %%边缘到边缘或者云
        if sa == size(M,2)+1 || sb == size(M,2)+1
            t = round(trans * 80 * 10^-9,3);
        else
            t = round(trans * 17.77 * 10^-9,3);
        end
    end
    if (sa ~= sb)
        if (sa == 0 && sb ~= 0) || (sa ~= 0 && sb == 0)
            if sa ~= 0
                sb = sa;
                sa =0;
            end
            if sb == size(M,2)+1
                t=round(trans * 7.81 * 10^-9 + trans * 80 * 10^-9,3);
            else
                rangecar=findedgecar(M,x);
                rangecar=rangecar(2:end);
                if ismember(sb,rangecar)
                    t=round(trans * 7.81 * 10^-9 ,3);
                else
                    t = round(trans * (17.77 * 10^-9 + 7.81 * 10^-9),3);
                end
            end
        end
    end
    if sa == sb
        t=0;
    end

end

function sucpos=findsucpos(B,i,j)    %%找出后继任务的位置
    sucpos=[];
    suc=findsuc(B,i,j);
    for n = suc
        sucpos=[sucpos,B(i).nodes(n+1).where];
    end
end

function B=resort(B)  %%排序
    for i = 1:size(B,2)
        for j = size(B(i).nodes,1)-1 : -1 : 0
            B(i).nodes(j+1).rank = round(rerank(B,i,j),3);
        end
    end
end

function [edges,nodes]=creategraph() 
% 创建节点
    node = 1:10;
    % 初始化边列表
    layer0=[0];
    % 第一层节点
    layer1 = node(1:3);
    % 第二层节点
    layer2 = node(4:5);
    % 第三层节点
    layer3 = node(6:7);
    %第四层节点
    layer4 = node(8:10);
    layer5=[11];
    % 连接虚拟任务
    n=1;
    for i=1:3
        edges(n)=struct('pre',0,'suc',i,'trans',(12+4*rand())*10^6/10);
        n=n+1;
    end

    % 连接第一层和第二层
    for i = layer1
        a=randi(2);
        len=length(layer2);
        x=randperm(len,a);
        for j=x
            edges(n) = struct("pre",i,'suc',layer2(j),'trans',(12+4*rand())*10^6/10);
            n=n+1;
        end
    end
    % 连接第二层和第三层
    for i = layer2
        a=randi(2);
        len=length(layer3);
        x=randperm(len,a);
        for j=x
            edges(n) = struct("pre",i,'suc',layer3(j),'trans',(12+4*rand())*10^6/10);
            n=n+1;
        end
    end
    %连接第三层和第四层
    for i = layer3
        a=randi(2);
        len=length(layer4);
        x=randperm(len,a);
        for j=x
            edges(n) = struct("pre",i,'suc',layer4(j),'trans',(12+4*rand())*10^6/10);
            n=n+1;
        end
    end
    % 连接虚拟任务
    for i=layer4
        edges(n) = struct("pre",i,'suc',11,'trans',(12+4*rand())*10^6/10);
        n=n+1;
    end
    x=unique([edges.suc]);
    xx=setdiff(node,x);
    for m=xx
        edges(n) = struct("pre",0,'suc',m,'trans',(12+4*rand())*10^6/10);
        n=n+1;
    end
    edgestable=struct2table(edges);
    edgestable=sortrows(edgestable,[1,2]);
    edges=table2struct(edgestable);
    n=2;
    nodes(1)=struct('order',0,'comp',0,'rank',0,'st',0,'ft',0,'where',-1,'statue',0 ,'rtc',-1);
    for i = node
        nodes(n)=struct('order',i,'comp',fix(2000+1000*rand()/1)/10,'rank',0,'st',0,'ft',0,'where',-1,'statue',0 ,'rtc',-1);
        n=n+1;
    end
    nodes(n)=struct('order',n-1,'comp',0,'rank',0,'st',0,'ft',0,'where',-1,'statue',0 ,'rtc',-1);
    nodes=nodes';
end

function B=createB(a) %创建用户
    list=linspace(1,1000,a+1);
    list=list(2:end);
    xlabel_matrix = reshape(list, a/10, []);
    xlabel=[];
    for i =1:size(xlabel_matrix,1)
        xlabel=[xlabel,xlabel_matrix(i,:)];
    end
    for i = 1:a
        [edges,nodes]=creategraph();
        if mod(i,20)<=10
            flag=1;
        else
            flag=-1;
        end
        r=i*(10/a);
        B(i)=struct('order',i,'v',flag*randi([10,20]),'xlabel',xlabel(i),'edges',edges,'nodes',nodes,'r',round(r,3),'req',r+5,"schedulelist",[],"f",1000,'c',10,'key',[],"worktime",0);
        workload=0;
        for x = 1:size(B(i).nodes,1)
            workload=workload+B(i).nodes(x).comp;
        end
        req=workload/5000*2+r;
        B(i).req=round(req,3);
    end
end
function M=createM(a) %%创建边缘服务器
    p=[4000,4500,5000,5500,6000];
    c=[32,40.5,50,60.5,72];
    for i = 1: a
        x=mod(i,5);
        if x == 0
            x = 5;
        end
        M(i)=struct('order',i,'f',p(x),'c',c(x),'pos',50*i,"schedulelist",[],"worktime",0);
    end
end

function Cloud = createCloud(a)
    Cloud = struct('order',1,'f',20000,'c',300,'schedulelist',[]);
end

%%%-------------------------------------------------------------------------------------------------%%%
