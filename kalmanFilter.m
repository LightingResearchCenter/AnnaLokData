function kfOutput = kalmanFilter(input)
%KALMANFILTER Summary of this function goes here
%   Detailed explanation goes here

    MAlen = 100; % moving average filter length
    N = 15; % lookback window length for covariance estimation
    kfOutput = StandardKalmanFilter(input', MAlen, N, 'EWMA');
	kfOutput = kfOutput(114:end);
	
	% Plot results
	figure
	subplot(2,1,1)
	%input = input - min(input);
	%input = input/max(input);
	plot(input(114:end),'b');
	title('Activity Data');
	hold on;
	grid on;
	subplot(2,1,2)
	%kfOutput = kfOutput - min(kfOutput((MAlen+N-1):end));
	%kfOutput= kfOutput/max(kfOutput((MAlen+N-1):end));
	plot(kfOutput,'r');
	hold on;
	grid on;
	kfOutput = kfOutput';
end

